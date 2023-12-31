using System;
using System.Linq;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using CarDetectorApp.VisionClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using VideoIndexerClient.model;
using static VideoIndexerClient.Utils.Consts;
using VIClient = VideoIndexerClient.VideoIndexerClient;

namespace CarDetectorApp
{
    public class IndexingEventHandler
    {
        private const string IndexingLogsCategory = "IndexingLogs";
        private const string SuccessRt = "Success";
        private const string IndexFinishEvent = "IndexingFinished";
        private const string ReindexFinishEvent = "ReindexingFinished";
        private static readonly string[] MonitoredEvents = { IndexFinishEvent, ReindexFinishEvent };

        private readonly ILogger _logger;
        private readonly CognitiveVisionClient _cognitiveVisionClient;
        private readonly Lazy<VIClient> _videoIndexerClientLazy = new(InitVideoIndexerClient);
        private VIClient VideoIndexerClient => _videoIndexerClientLazy.Value;

        public IndexingEventHandler()
        {
            _logger = AppLogger.Logger;
            _cognitiveVisionClient = new CognitiveVisionClient(_logger);
        }

        public async Task OnEventReceived(EventData[] events)
        {
            var processors = events.Select(ToIndexEvet)
                .Where(evt => evt != null)
                .SelectMany(evt => evt.records)
                .Select(ProcessIndexingRecord);

            await Task.WhenAll(processors);
        }

        public async Task<string> ProcessIndexingRecord(IndexEventRecord idxEventRecord)
        {
            if (!HandleRecord(idxEventRecord))
            {
                return string.Empty;
            }

            var videoId = idxEventRecord?.properties.videoId;
            var operationName = idxEventRecord?.operationName;
            
            if ( string .IsNullOrEmpty(operationName) || string.IsNullOrEmpty(videoId))
                return string.Empty;
            
            _logger.LogInformation("Processing Started on VideoId: {0}, Operation: {1}", videoId, operationName);

            //Step 1 : Get the Video Insights from the API 
            var videoInsights = await VideoIndexerClient.GetVideoIndexInsights(videoId);
            if (videoInsights == null)
            { 
                _logger.LogError("Could not Fetch Insights Data on VideoId: {0}", videoId);
                return string.Empty;
            }

            var carFrameData = videoInsights.Videos
                .Select(v => v.Insights)
                .SelectMany(insight => insight.DetectedObjects)
                .Where(dto => dto.Type.Equals(DetectObjectType))
                .Select(dto=> new FrameData(dto.Id.ToString(), 1,
                    VideoIndexerClient.GetThumbnailRequestUri(videoId, dto.ThumbnailId),dto.TimePairs))
                .ToList();

            if (!carFrameData.Any())
            {
                _logger.LogInformation("No Cars Detected on VideoId: {0}", videoId);
                return string.Empty;
            }

            //Step 2 : Send Each Thumbnail to Florence Model
            _logger.LogInformation("Processing Florence Started on VideoId: {0}, Operation: {1}", videoId, operationName);
            var customInsights = await _cognitiveVisionClient.ExtractCustomInsights(carFrameData);
            _logger.LogInformation("Processing Florence Completed on VideoId: {0}, Operation: {1}", videoId, operationName);

            // postprocessing for insights 
            _logger.LogInformation("Calling Path Index on Video Indexer API -Started");
            var pathResultCode = await VideoIndexerClient.PatchIndex(videoId, customInsights, videoInsights.HasCustomInsights);
            _logger.LogInformation("Calling Path Index on Video Indexer API -Completed. ResultCode: {0}", pathResultCode);
            return pathResultCode;
        }

        private static IndexEvent ToIndexEvet(EventData evt) => JsonConvert.DeserializeObject<IndexEvent>(evt.EventBody.ToString());

        private static bool HandleRecord(IndexEventRecord record)
        {
            AppLogger.Logger.LogInformation("Got Recrod : category {0}, Operation: {1}, Result: {2} ",record.category,record.operationName,record.resultType);
            return record.category.Equals(IndexingLogsCategory)
                && record.resultType.Equals(SuccessRt)
                && MonitoredEvents.Contains(record.operationName);
        }
        /// <summary>
        /// VI Factory For Lazy Pattern
        /// </summary>
        /// <returns></returns>
        private static VIClient InitVideoIndexerClient()
        {
            var videoIndexerClient = new VIClient(AppLogger.Logger, new Account { Location = Location, Properties = new AccountProperties() { Id = ViAccountId } });
            videoIndexerClient.Authenticate().Wait();
            return videoIndexerClient;
        }
    }
}
