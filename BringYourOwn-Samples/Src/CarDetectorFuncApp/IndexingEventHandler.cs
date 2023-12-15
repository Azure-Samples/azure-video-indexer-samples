﻿using System;
using System.IO;
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
        private const string INDEXING_LOGS_CATEGORY = "IndexingLogs";
        private const string SUCCESS_RT = "Success";
        private const string INDEX_FINISH_EVENT = "IndexingFinished";
        private const string REINDEX_FINISH_EVENT = "ReindexingFinished";
        private static string[] MonitoredEvents = { INDEX_FINISH_EVENT, REINDEX_FINISH_EVENT };

        private readonly ILogger _logger;
        private readonly CognitiveVisioClient _cognitiveVisioClient;
        private readonly Lazy<VIClient> _videoIndexerClientLazy = new(InitVideoIndexerClient);
        private VIClient VideoIndexerClient => _videoIndexerClientLazy.Value;

        public IndexingEventHandler()
        {
            _logger = AppLogger.Logger;
            _cognitiveVisioClient = new CognitiveVisioClient(_logger);
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
            var videoInsights = await VideoIndexerClient.GetVideoInsights(videoId);
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
                    VideoIndexerClient.GetThumbnailRequestURI(videoId, dto.ThumbnailId),dto.TimePairs))
                .ToList();

            if (!carFrameData.Any())
            {
                _logger.LogInformation("No Cars Detected on VideoId: {0}", videoId);
                return string.Empty;
            }
            
            //Step 2 : Send Each Thumbnail to Florence Model
            _logger.LogInformation("Processing Florence Started on VideoId: {0}, Operation: {1}", videoId, operationName);
            var customInsights = await _cognitiveVisioClient.ExtractCustomInsights(carFrameData);
            _logger.LogInformation("Processing Florence Completed on VideoId: {0}, Operation: {1}", videoId, operationName);

            // postprocessing for insights 
            _logger.LogInformation("Calling Path Index on Video Indexer API -Started");
            var pathResultCode = await VideoIndexerClient.PatchIndex(videoId, customInsights);
            _logger.LogInformation("Calling Path Index on Video Indexer API -Completed. ResultCode: {0}", pathResultCode);
            return pathResultCode;
        }

        private static IndexEvent ToIndexEvet(EventData evt) => JsonConvert.DeserializeObject<IndexEvent>(evt.EventBody.ToString());

        private static bool HandleRecord(IndexEventRecord record)
        {
            AppLogger.Logger.LogInformation("Got Recrod : category {0}, Operation: {1}, Result: {2} ",record.category,record.operationName,record.resultType);
            return record.category.Equals(INDEXING_LOGS_CATEGORY)
                && record.resultType.Equals(SUCCESS_RT)
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