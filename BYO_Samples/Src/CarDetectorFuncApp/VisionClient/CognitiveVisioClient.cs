using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using VideoIndexerClient.model;
using VideoIndexerClient.Utils;
using static VideoIndexerClient.Utils.Consts;


namespace CarDetectorApp.VisionClient
{
    public class CognitiveVisioClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger _logger;
        private readonly string _queryParams;
        private int _idGenerator = 0;

        private const double ConfidenceThreshold = 0.4f;
        private const int MAX_THREADS = 6; // Florence S1 tier support max of 10/TPQ 
        

        public CognitiveVisioClient(ILogger logger)
        {
            System.Net.ServicePointManager.SecurityProtocol |= System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls13;
            _httpClient = HttpClientUtils.CreateHttpClient();
            _logger = logger;

            _queryParams = new Dictionary<string, string>
            {
                { "visualFeatures", "customModel" },
                { "CustomModel-ModelName", CognitiveVisionCustomModelName },
                { "apiVersion" , CognitiveVisionApiVersion }
            }.CreateQueryString();

            _httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", CognitiveApiSubscriptionKey);
        }

        public async Task<CustomInsights> ExtractCustomInsights(IEnumerable<FrameUriData> videoFrames)
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

        private async Task<List<CustomInsightResult>> CreateCustomModelObject(FrameUriData videoFrame)
        {
            var florenceResults = await SingleFrameProcessing(videoFrame.FilePath);
            if (florenceResults?.CustomModelResult == null)
                return new List<CustomInsightResult>();

            return florenceResults.CustomModelResult.Objects
                .Where(detectedObj => detectedObj.Classifications[0].Confidence > ConfidenceThreshold)
                .Select(detectedObject =>
                {
                    return new CustomInsightResult
                    {
                        Id = Interlocked.Increment(ref _idGenerator),
                        Type = detectedObject.Classifications[0].Label,
                        //Metadata is a custom field that can be used for many purposes. here we demonstrate a bounding box data usage.
                        Metadata = $"\"boundingBox:\"{JsonConvert.SerializeObject(detectedObject.BoundingBox)}",
                        Instances = new[]
                        {
                            new Instance
                            {
                                Start = videoFrame.StartTime, 
                                AdjustedStart = videoFrame.StartTime,
                                End = videoFrame.EndTime,
                                AdjustedEnd = videoFrame.EndTime,
                                Confidence = detectedObject.Classifications[0].Confidence
                            }
                        }
                    };
                }).ToList();
        }

        public async Task<Contracts.FlorenceResults?> SingleFrameProcessing(string imageUrl)
        {
            var filename = imageUrl[..imageUrl.IndexOf("?", StringComparison.Ordinal)];
            _logger.LogInformation("Processing Florence on imageUrl {0} Started", filename);

            try
            {
                var requestUri = $"{CognitiveVisionURI}?{_queryParams}";
                var fileStream = await _httpClient.GetStreamAsync(imageUrl);

                //We need to convert to Memory Stream in order to calculate length
                var memoryStream = new MemoryStream();
                await fileStream.CopyToAsync(memoryStream);
                memoryStream.Position = 0;

                using var streamContent = new StreamContent(memoryStream);
                streamContent.Headers.Clear();
                streamContent.Headers.Add("Content-Type", "application/octet-stream");
                streamContent.Headers.Add("Content-Length", memoryStream.Length.ToString());

                var response = _httpClient.PostAsync(requestUri, streamContent).Result;
                response.EnsureSuccessStatusCode();
                var resultString = await response.Content.ReadAsStringAsync();

                _logger.LogInformation("Processing Florence on imageUrl {0} Finished", filename);
                return JsonConvert.DeserializeObject<Contracts.FlorenceResults>(resultString);
            }
            catch (Exception ex)
            {
                _logger.LogError("Could not call Florence Model. Reason: {0}", ex.Message);
            }
            return null;
        }
    }
}
