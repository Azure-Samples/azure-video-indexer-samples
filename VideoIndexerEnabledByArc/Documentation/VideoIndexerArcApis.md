# Video Indexer Arc APIs Documentation

**Version:** v1  
**OpenAPI:** 3.0.1

## Authentication

All endpoints require **Bearer Token** authentication (JWT).

```
Authorization: Bearer {your-jwt-token}
```

## API Categories

### 1. Agent Jobs
Manage automated agent jobs for video processing.

- **POST** `/Accounts/{accountId}/AgentJobs` - Create agent job
- **GET** `/Accounts/{accountId}/AgentJobs` - List all agent jobs
- **GET** `/Accounts/{accountId}/AgentJobs/{agentJobId}` - Get agent job by ID
- **PUT** `/Accounts/{accountId}/AgentJobs/{agentJobId}` - Update agent job
- **DELETE** `/Accounts/{accountId}/AgentJobs/{agentJobId}` - Delete agent job

### 2. Agents
Retrieve available AI agents.

- **GET** `/Accounts/{accountId}/agents` - Get available agents list

### 3. Chats
Manage conversation chats with AI agents.

- **POST** `/Accounts/{accountId}/chats` - Create new chat
- **GET** `/Accounts/{accountId}/chats` - List all chats
- **GET** `/Accounts/{accountId}/chats/{chatId}` - Get chat by ID
- **DELETE** `/Accounts/{accountId}/chats/{chatId}` - Delete chat
- **POST** `/Accounts/{accountId}/chats/{chatId}/messages` - Send message
- **GET** `/Accounts/{accountId}/chats/{chatId}/messages` - Get chat messages
- **GET** `/Accounts/{accountId}/chats/{chatId}/messages/{messageId}` - Get message by ID
- **DELETE** `/Accounts/{accountId}/chats/{chatId}/messages/{messageId}` - Delete message

### 4. Extensions
Get extension details and configuration.

- **GET** `/Accounts/{accountId}/extension` - Get extension details
- **GET** `/info` - Get general extension info

### 5. Indexing
Upload and manage video indexing operations.

- **POST** `/Accounts/{accountId}/Videos` - Upload video for indexing
- **GET** `/Accounts/{accountId}/Videos/{videoId}/Index` - Get video index
- **PUT** `/Accounts/{accountId}/Videos/{videoId}/Index` - Update video index
- **PATCH** `/Accounts/{accountId}/Videos/{videoId}/Index` - Update video index (partial)
- **PUT** `/Accounts/{accountId}/Videos/{videoId}/ReIndex` - Re-index video

### 6. Videos
Manage videos and retrieve video information.

- **GET** `/Accounts/{accountId}/Videos` - List all videos
- **GET** `/Accounts/{accountId}/Videos/{videoId}` - Get video details
- **DELETE** `/Accounts/{accountId}/Videos/{videoId}` - Delete video
- **DELETE** `/Accounts/{accountId}/Videos/{videoId}/SourceFile` - Delete video source file
- **GET** `/Accounts/{accountId}/Videos/{videoId}/Captions` - Get video captions
- **GET** `/Accounts/{accountId}/Videos/{videoId}/Sprite` - Get video sprite
- **GET** `/Accounts/{accountId}/Videos/{videoId}/Thumbnails/{thumbnailId}` - Get thumbnail
- **GET** `/Accounts/{accountId}/Videos/{videoId}/streaming-url` - Get streaming URL
- **GET** `/Accounts/{accountId}/Videos/{videoId}/streaming-manifest/{manifestFile}` - Download manifest
- **GET** `/Accounts/{accountId}/Videos/{videoId}/streaming-file/{fileName}` - Download streaming file
- **GET** `/Accounts/{accountId}/Videos/{videoId}/FramesFilePaths` - Get frames file paths
- **GET** `/Accounts/{accountId}/Videos/{videoId}/tags` - Get video tags
- **PUT** `/Accounts/{accountId}/Videos/{videoId}/tags/{tagId}` - Add tag to video
- **DELETE** `/Accounts/{accountId}/Videos/{videoId}/tags/{tagId}` - Remove tag from video
- **GET** `/Accounts/{accountId}/Videos/{videoId}/insightTypes` - Get video insight types
- **GET** `/Accounts/{accountId}/Videos/{videoId}/liveInsights/Pages/{pageNumber}` - Get recorded insights page by number
- **GET** `/Accounts/{accountId}/Videos/{videoId}/liveInsights/Pages` - Get recorded insights page by time

### 7. Live Cameras
Manage live camera feeds and configurations.

- **POST** `/Accounts/{accountId}/cameras` - Add new camera
- **GET** `/Accounts/{accountId}/cameras` - List all cameras
- **GET** `/Accounts/{accountId}/cameras/{cameraId}` - Get camera by ID
- **PATCH** `/Accounts/{accountId}/cameras/{cameraId}` - Update camera
- **DELETE** `/Accounts/{accountId}/cameras/{cameraId}` - Remove camera
- **GET** `/Accounts/{accountId}/cameras/{cameraId}/Thumbnail` - Get camera thumbnail
- **GET** `/Accounts/{accountId}/cameras/{cameraId}/streaming-manifest/{manifestFile}` - Get live streaming manifest
- **GET** `/Accounts/{accountId}/cameras/{cameraId}/streaming-file/{fileName}` - Download live streaming file

### 8. Live Insights
Retrieve real-time insights from camera feeds.

- **GET** `/Accounts/{accountId}/Cameras/{cameraId}/Insights` - Get live insights by date/time

### 9. Live Presets
Manage indexing presets for live cameras.

- **POST** `/Accounts/{accountId}/Presets` - Create preset
- **GET** `/Accounts/{accountId}/Presets` - List all presets
- **GET** `/Accounts/{accountId}/Presets/{presetId}` - Get preset by ID
- **PATCH** `/Accounts/{accountId}/Presets/{presetId}` - Update preset
- **DELETE** `/Accounts/{accountId}/Presets/{presetId}` - Delete preset

### 10. Custom Insights
Create and manage custom AI insights.

- **POST** `/Accounts/{accountId}/customInsights` - Create custom insight
- **GET** `/Accounts/{accountId}/customInsights` - List custom insights
- **GET** `/Accounts/{accountId}/customInsights/{insightId}` - Get custom insight by ID
- **PUT** `/Accounts/{accountId}/customInsights/{insightId}` - Update custom insight
- **DELETE** `/Accounts/{accountId}/customInsights/{insightId}` - Delete custom insight
- **POST** `/Accounts/{accountId}/customInsights/{insightId}/Images` - Add images batch to custom insight
- **GET** `/Accounts/{accountId}/customInsights/{insightId}/Images/{imageId}` - Get image from custom insight
- **DELETE** `/Accounts/{accountId}/customInsights/{insightId}/Images/{imageId}` - Delete image from custom insight

### 11. Spatial Analysis Rules
Configure spatial analysis for camera zones.

- **POST** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules` - Create spatial analysis rule
- **GET** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules` - List spatial analysis rules
- **GET** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules/{spatialAnalysisRuleId}` - Get rule by ID
- **PATCH** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules/{spatialAnalysisRuleId}` - Update rule
- **DELETE** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules/{spatialAnalysisRuleId}` - Delete rule
- **PUT** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules/{ruleId}/tags/{tagId}` - Add tag to rule
- **DELETE** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules/{ruleId}/tags/{tagId}` - Delete tag from rule

### 12. Monitored Zones
Manage monitored zones for spatial analysis.

- **POST** `/Accounts/{accountId}/monitoredZones` - Create monitored zone
- **GET** `/Accounts/{accountId}/monitoredZones` - List monitored zones
- **GET** `/Accounts/{accountId}/monitoredZones/{monitoredZoneId}` - Get zone by ID
- **PATCH** `/Accounts/{accountId}/monitoredZones/{monitoredZoneId}` - Update zone
- **DELETE** `/Accounts/{accountId}/monitoredZones/{monitoredZoneId}` - Delete zone

### 13. Tags
Manage tags for organizing content.

- **POST** `/Accounts/{accountId}/tags` - Create tag
- **GET** `/Accounts/{accountId}/tags` - List all tags
- **GET** `/Accounts/{accountId}/tags/{tagId}` - Get tag by ID
- **DELETE** `/Accounts/{accountId}/tags/{tagId}` - Delete tag

### 14. Jobs
Track job progress and status.

- **GET** `/Accounts/{accountId}/Jobs/{jobId}` - Get indexing job status

### 15. Textual Summarization
Generate and manage video summaries.

- **POST** `/Accounts/{accountId}/Videos/{videoId}/Summaries/Textual` - Summarize video
- **GET** `/Accounts/{accountId}/Videos/{videoId}/Summaries/Textual` - List video summaries
- **GET** `/Accounts/{accountId}/Videos/{videoId}/Summaries/Textual/{summaryId}` - Get summary by ID
- **DELETE** `/Accounts/{accountId}/Videos/{videoId}/Summaries/Textual/{summaryId}` - Delete summary
- **GET** `/Accounts/{accountId}/Videos/{videoId}/Summaries/Textual/{summaryId}/report` - Get summary report

### 16. Translation
Translate video insights to different languages.

- **POST** `/Accounts/{accountId}/Videos/{videoId}/Translate` - Translate video index

### 17. Search
Natural language search across video content.

- **POST** `/Accounts/{accountId}/videos/search` - Search videos using natural language

### 18. Prompt Content
Generate prompt content for LLM integration.

- **POST** `/Accounts/{accountId}/Videos/{videoId}/PromptContent` - Create prompt content
- **GET** `/Accounts/{accountId}/Videos/{videoId}/PromptContent` - Get prompt content

### 19. Languages & Models
Get supported languages and models.

- **GET** `/SupportedLanguages` - Get supported languages
- **GET** `/Accounts/{accountId}/LanguageModels` - Get language models
- **GET** `/Accounts/{accountId}/SupportedAIs` - Get supported AI models
- **GET** `/Accounts/{accountId}/builtInInsightTypes` - List built-in insight types
- **GET** `/Accounts/{accountId}/insightTypes` - List insight types

### 20. Miscellaneous
Additional utility endpoints.

- **GET** `/Accounts/{accountId}/VideoInfo` - Get video network info
- **GET** `/Accounts/{accountId}/mediaServer/config` - Get media server config

## Common Parameters

### Path Parameters
- `accountId` (UUID, required) - Account identifier
- `videoId` (string, required) - Video identifier
- `cameraId` (UUID, required) - Camera identifier

### Query Parameters
- `pageSize` (integer, 1-1000, default: 25) - Number of results per page
- `skip` (integer, default: 0) - Number of records to skip
- `language` (string) - Language code (e.g., en-US, fr-FR)
- `sortBy` (string) - Sort field with optional `-` prefix for descending order

## Response Codes

### Success Codes
- **200** - OK
- **201** - Created
- **202** - Accepted
- **204** - No Content
- **303** - See Other

### Error Codes
- **400** - Bad Request
- **401** - Unauthorized
- **403** - Forbidden
- **404** - Not Found
- **409** - Conflict
- **429** - Too Many Requests
- **500** - Server Error
- **507** - Insufficient Storage

## Supported Languages

The API supports 50+ languages including:
- Arabic (ar-EG)
- Chinese Simplified (zh-Hans)
- Chinese Traditional (zh-Hant)
- English (en-US)
- French (fr-FR)
- German (de-DE)
- Hebrew (he-IL)
- Japanese (ja-JP)
- Korean (ko-KR)
- Spanish (es-ES)
- And many more...

## Indexing Presets

- **Default** - Full indexing with all features
- **Basic** - Basic indexing
- **BasicAudio** - Audio-only indexing
- **BasicVideo** - Video-only indexing

## Streaming Presets

- **Default** - Standard streaming quality
- **SingleBitrate** - Single bitrate streaming
- **NoStreaming** - No streaming output

## Notes

1. All timestamps use ISO 8601 format
2. UUIDs are used for resource identifiers
3. Pagination is supported via `pageSize` and `skip` parameters
4. Maximum file upload size and duration limits apply
5. Rate limiting is enforced on API calls
6. Bearer tokens expire and must be refreshed

---

*For detailed schema information and examples, refer to the OpenAPI specification file.*
