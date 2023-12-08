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
using Newtonsoft.Json;
using VideoIndexerClient.model;
using VideoIndexerClient.Utils;
using static VideoIndexerClient.Utils.Consts;
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.

namespace CarDetectorApp.VisionClient
{
    public class CognitiveVisioClient
    {
        private readonly VisionServiceOptions _serviceOptions;
        private readonly ImageAnalysisOptions _analysisOptions;
        private readonly ILogger _logger;
        
        private int _idGenerator;

        private const double ConfidenceThreshold = 0.4f;
        private const int MAX_THREADS = 6; // Florence S1 tier support max of 10/TPQ 
        

        public CognitiveVisioClient(ILogger logger)
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
            var options = new ParallelOptions { MaxDegreeOfParallelism = MAX_THREADS };
            await Parallel.ForEachAsync(videoFrames, options, async (frameData, _) =>
            {
                var intermediateResult = await CreateCustomModelObject(frameData);
                aggregateResults.AddRange(intermediateResult);
                //Ensure we fill into 1 second
                await Task.Delay(400, _);
            });

            return new CustomInsights
            {
                Results = aggregateResults.ToArray(),
                Name = "Cars"
            };
        }

        private async Task<List<CustomInsightResult>> CreateCustomModelObject(FrameData videoFrame)
        {
            var florenceResults = await SingleFrameProcessing(videoFrame.FilePath);
            if (florenceResults == null || !florenceResults.Any())
                return new List<CustomInsightResult>();

            var computerVisionResults =  florenceResults
                .Where(detectedObj => detectedObj.Confidence > ConfidenceThreshold)
                .Select(detectedObject =>
                {
                    var classificationType = detectedObject.Name;
                    if (!int.TryParse(videoFrame.Name, out var resultId))
                    {
                        resultId = Interlocked.Increment(ref _idGenerator);
                    }
                    return new CustomInsightResult
                    {
                        Id =  resultId,
                        Type = classificationType,
                        //Metadata is a custom field that can be used for many purposes. here we demonstrate a bounding box data usage.
                        Metadata = $"{{\"BoundingBox\": {detectedObject.BoundingBox}}}",
                        Instances = videoFrame.StartEndPairs.Select(timePair => new Instance
                        {
                            Start = timePair.StartTime,
                            AdjustedStart = timePair.StartTime,
                            End = timePair.EndTime,
                            AdjustedEnd = timePair.EndTime,
                            Confidence = detectedObject.Confidence
                        }).ToArray()
                    };
                }).ToList();

            //Perform Folding on the results : Group together based on sae type and id
            return computerVisionResults
                .GroupBy(result => new { result.Type, result.Id })
                .Select(group => new CustomInsightResult
                {
                    Type = group.Key.Type,
                    Id = group.Key.Id,
                    Instances = group.SelectMany(result => result.Instances).ToArray()
                })
                .ToList();
        }

        public async Task<DetectedObjects> SingleFrameProcessing(string imageUrl)
        {
            var filename = imageUrl[..imageUrl.IndexOf("?", StringComparison.Ordinal)];
            try
            {
                //Source Reference : https://github.com/Azure-Samples/azure-ai-vision-sdk/blob/main/samples/csharp/image-analysis/dotnet/Samples.cs
                using var imageSource = VisionSource.FromUrl(new Uri(imageUrl));
                using var analyzer = new ImageAnalyzer(_serviceOptions, imageSource, _analysisOptions);
                var result = await analyzer.AnalyzeAsync();
                if (result?.CustomObjects?.Count > 0)
                {
                    _logger.LogInformation("Processing Florence on imageUrl {0} Finished with result {1}", filename, result.Objects.Count);
                    return result.CustomObjects;
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
