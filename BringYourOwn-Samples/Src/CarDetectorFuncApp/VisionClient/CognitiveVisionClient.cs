using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Azure.AI.Vision.Common;
using Azure;
using Azure.AI.Vision.ImageAnalysis;
using Microsoft.Extensions.Logging;
using VideoIndexerClient.model;
using static VideoIndexerClient.Utils.Consts;

namespace CarDetectorApp.VisionClient
{
    public class CognitiveVisionClient
    {
        private readonly VisionServiceOptions _serviceOptions;
        private readonly ImageAnalysisOptions _analysisOptions;
        private readonly ILogger _logger;
        
        private int _idGenerator;

        private const double ConfidenceThreshold = 0.4f;
        private const int MaxThreads = 6; // Florence S1 tier support max of 10/TPQ 
        

        public CognitiveVisionClient(ILogger logger)
        {
            System.Net.ServicePointManager.SecurityProtocol |= System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls13;
            _logger = logger;
            _serviceOptions = new VisionServiceOptions(CognitiveVisionUri, new AzureKeyCredential(CognitiveApiSubscriptionKey));
            _analysisOptions = new ImageAnalysisOptions()
            {
                Features = ImageAnalysisFeature.Objects,
                ModelName = CognitiveVisionCustomModelName,
            }; 
        }

        /// <summary>
        /// Extracts Custom Insights from a video by Calling the Cognitive Vision API
        /// </summary>
        /// <param name="videoFrames"></param>
        /// <returns></returns>
        public async Task<CustomInsights> ExtractCustomInsights(IEnumerable<FrameData> videoFrames)
        {
            _idGenerator = 0;
            var aggregateResults = new ConcurrentBag<CustomInsightResult>();
            var options = new ParallelOptions { MaxDegreeOfParallelism = MaxThreads };
            await Parallel.ForEachAsync(videoFrames, options, async (frameData, _) =>
            {
                var modelResult = await ToVideoIndederCustomModelObject(frameData);
                aggregateResults.Add(modelResult);
                await Task.Delay(200, _); //avoid throttling
            });

            return new CustomInsights
            {
                Results = aggregateResults.OrderBy(item => item.Id).ToArray(),
                Name = "Cars",
                DisplayName = "Custom Model - Cars"
            };
        }

        private async Task<CustomInsightResult> ToVideoIndederCustomModelObject(FrameData videoFrame)
        {
            var contentTags = await SingleFrameProcessing(videoFrame.FilePath);
            if (contentTags == null || !contentTags.Any())
                return null;
            
            //we will always return the model with the highest confidence result
            return contentTags
                .Where(contentTag => contentTag.Confidence > ConfidenceThreshold)
                .OrderByDescending(contentTag => contentTag.Confidence)
                .Select(contentTag =>
                {
                    var classificationType = contentTag.Name;
                    if (!int.TryParse(videoFrame.Name, out var resultId))
                    {
                        resultId = Interlocked.Increment(ref _idGenerator);
                    }

                    return new CustomInsightResult
                    {
                        Id = resultId,
                        Type = $"{classificationType}",
                        SubType = $"{classificationType}_{resultId}",
                        //Metadata is a custom field that can be used for many purposes. here we demonstrate a bounding box data usage.
                        Instances = videoFrame.StartEndPairs.Select(timePair => new Instance
                        {
                            Start = timePair.StartTime,
                            AdjustedStart = timePair.StartTime,
                            End = timePair.EndTime,
                            AdjustedEnd = timePair.EndTime,
                            Confidence = contentTag.Confidence
                        }).ToArray()
                    };
                }).First();
        }

        public async Task<ContentTags> SingleFrameProcessing(string imageUrl)
        {
            var filename = imageUrl[..imageUrl.IndexOf("?", StringComparison.Ordinal)];
            try
            {
                //Source Reference : https://github.com/Azure-Samples/azure-ai-vision-sdk/blob/main/samples/csharp/image-analysis/dotnet/Samples.cs
                using var imageSource = VisionSource.FromUrl(new Uri(imageUrl));
                using var analyzer = new ImageAnalyzer(_serviceOptions, imageSource, _analysisOptions);
                var result = await analyzer.AnalyzeAsync();
                if (result?.CustomTags?.Count > 0)
                {
                    _logger.LogInformation("Processing Florence on imageUrl {0} Finished. Detected {1} results", filename, result.CustomTags.Count);
                    return result.CustomTags;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError("Could not call Florence Model. Reason: {0}", ex.Message);
            }
            return null;
        }
    }
}
