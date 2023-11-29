using System.Linq;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using CarDetectorApp.VisionClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using VideoIndexerClient.model;
using VideoIndexerClient.Utils;
using static VideoIndexerClient.Utils.Consts;
using VIClient = VideoIndexerClient.VideoIndexerClient;

namespace CarDetectorApp
{
    public class IndexingEventHandler
    {
        private const string INDEXING_LOGS_CATEGORY = "IndexingLogs";
        private const string SUCCESS_RT = "Success";
        private const string INDEX_FINISH_EVENT = "IndexingFinished";
        private const string REINDEX_FINISH_EVENT = "ReindexingFinished";
        private static string[] MonitoredEvents = { INDEX_FINISH_EVENT, REINDEX_FINISH_EVENT };

        private readonly ILogger _logger;
        private readonly CognitiveVisioClient _cognitiveVisioClient;
        private readonly VIClient _videoIndexerClient;

        public IndexingEventHandler(ILogger logger)
        {
            _logger = logger;
            _cognitiveVisioClient = new CognitiveVisioClient(logger);
            _videoIndexerClient = new VIClient(logger, new Account { Location = Location, Properties = new AccountProperties() { Id = ViAccountId } });
            _videoIndexerClient.Authenticate(null).Wait();
        }

        public async Task OnEventReceived(EventData[] events)
        {
            //var processors = events.Select(ToIndexEvet)
            //    .Where(evt => evt != null)
            //    .SelectMany(evt => evt.records)
            //    .Select(ProcessIndexingRecored);

            //await Task.WhenAll(processors);

        }

        public async Task<string> ProcessIndexingRecored(IndexEventRecord? idxEventRecord)
        {
            //if (!HandleRecord(idxEventRecord))
            //    return string.Empty;
            //var videoId = idxEventRecord.properties.videoId;
            //var operationName = idxEventRecord.operationName;
            var videoId = "b72271397b";
            var operationName = INDEX_FINISH_EVENT;

            //Step1 : Get Video Artifacts
            var detectedObjects = await _videoIndexerClient.GetVideoArtifacts(videoId, ARTIFACT_TYPE_OD);
                
            if (detectedObjects == null)
            {
                _logger.LogError("Could not Fetch Artifact Data on VideoId: {0}", videoId);
                return string.Empty;
            }
            //Get All the video Frames
            _logger.LogInformation("Getting Video Frame SasURLs for video {0}", videoId);
            var frames = await _videoIndexerClient.GetVideoFrames(videoId);
            _logger.LogInformation("Got {0} Video Frames for video {1}", frames.Count, videoId);

            //Step 2 : Filter By Best Fit
            var detectedIds = detectedObjects.Results
                                    .Where(artifact=> artifact.Type.Equals(DetectObjectType))
                                    .SelectMany(dt => dt.Instances)
                                    .Where(detected => detected.IsBest)
                                    .Select(instance => instance.Frame).ToArray();
            var bestInstances = frames.Where(fr => detectedIds.Contains(fr.FrameIndex)).ToArray();
            _logger.LogInformation("Filtered {0} BestFit Frames for video {1}", bestInstances.Length, videoId);

            //Step 3 : Call Florence Model on Each Instance
            _logger.LogInformation("Processing Florence Started on VideoId: {0}, Operation: {1}", videoId, operationName);
                var customInsights = await _cognitiveVisioClient.ExtractCustomInsights(bestInstances);
            _logger.LogInformation("Processing Florence Completed on VideoId: {0}, Operation: {1}", videoId, operationName);

            // postprocessing for insights 
            // all: get the instance and the time 
            // getting all the flags and 

            _logger.LogInformation("Calling Path Index on Video Indexer API -Started");
            var pathResultCode = await _videoIndexerClient.PatchIndex(videoId, customInsights);
            _logger.LogInformation("Calling Path Index on Video Indexer API -Completed. ResultCode: {0}", pathResultCode);
            return pathResultCode;
        }

        private static IndexEvent ToIndexEvet(EventData evt) => JsonConvert.DeserializeObject<IndexEvent>(evt.EventBody.ToString());
        private static bool HandleRecord(IndexEventRecord record) => record.category.Equals(INDEXING_LOGS_CATEGORY)
                                                                     && record.resultType.Equals(SUCCESS_RT)
                                                                     && MonitoredEvents.Contains(record.operationName);
    }
}
