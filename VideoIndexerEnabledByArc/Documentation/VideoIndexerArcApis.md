# Video Indexer Arc APIs Documentation

**API Version:** v1  
**OpenAPI Specification:** 3.0.1  
**Authentication:** Bearer Token (JWT)

## Table of Contents
- [Authentication](#authentication)
- [Agent Jobs](#agent-jobs)
- [Agents](#agents)
- [Chats](#chats)
- [Extensions](#extensions)
- [Indexing](#indexing)
- [Videos](#videos)
- [Live Cameras](#live-cameras)
- [Live Insights](#live-insights)
- [Live Presets](#live-presets)
- [Custom Insights](#custom-insights)
- [Spatial Analysis Rules](#spatial-analysis-rules)
- [Monitored Zones](#monitored-zones)
- [Tags](#tags)
- [Jobs](#jobs)
- [Textual Summarization](#textual-summarization)
- [Translation](#translation)
- [Search](#search)
- [Prompt Content](#prompt-content)
- [Languages & Models](#languages--models)

---

## Authentication

All API endpoints require Bearer token authentication.

**Header:**
```
Authorization: Bearer {your-jwt-token}
```

---

## Agent Jobs

### Create Agent Job
**POST** `/Accounts/{accountId}/AgentJobs`

Creates a new automated agent job for video processing.

**Parameters:**
- `accountId` (path, required): UUID - Account identifier

**Request Body:**
```json
{
  "agentId": "uuid",
  "name": "string",
  "description": "string",
  "eventName": "string",
  "intervalInSeconds": 3600,
  "retentionInSeconds": 86400,
  "enabled": true,
  "prompt": "string",
  "callbackUrl": "https://example.com/callback",
  "cameraId": "uuid"
}
```

**Response 200:**
```json
{
  "id": "uuid",
  "agentId": "uuid",
  "name": "Job Name",
  "state": 1,
  "createTime": "2024-01-01T00:00:00Z",
  "lastUpdateTime": "2024-01-01T00:00:00Z"
}
```

**Error Responses:**
- 400: Agent job name can't be empty
- 401: Unauthorized
- 404: Account not found
- 500: Server Error

---

### List Agent Jobs
**GET** `/Accounts/{accountId}/AgentJobs`

**Query Parameters:**
- `pageSize` (optional): 1-1000, default: 25
- `skip` (optional): default: 0
- `cameraId` (optional): Filter by camera ID (array)

**Response 200:**
```json
{
  "results": [
    {
      "id": "uuid",
      "name": "Agent Job Name",
      "enabled": true,
      "state": 1
    }
  ],
  "nextPage": {
    "pageSize": 25,
    "skip": 0,
    "done": false
  }
}
```

---

### Get Agent Job
**GET** `/Accounts/{accountId}/AgentJobs/{agentJobId}`

**Response 200:** Returns agent job details

---

### Update Agent Job
**PUT** `/Accounts/{accountId}/AgentJobs/{agentJobId}`

**Request Body:** Same as Create Agent Job

---

### Delete Agent Job
**DELETE** `/Accounts/{accountId}/AgentJobs/{agentJobId}`

**Response 204:** No Content - Successfully deleted

---

## Agents

### Get Available Agents
**GET** `/Accounts/{accountId}/agents`

Retrieves the list of available AI agents.

**Query Parameters:**
- `pageSize`: 1-1000, default: 25
- `skip`: default: 0
- `sortBy`: Options: Name, AgentId, Description, CreateTime (use '-' prefix for desc)

**Response 200:**
```json
{
  "results": [
    {
      "agentId": "uuid",
      "name": "Agent Name",
      "description": "Agent description",
      "createTime": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

## Chats

### Create Chat
**POST** `/Accounts/{accountId}/chats`

Creates a new conversation chat.

**Response 201:**
```json
{
  "chatId": "uuid",
  "createTime": "2024-01-01T00:00:00Z"
}
```

**Error Responses:**
- 400: Invalid agent name
- 403: Insufficient permissions for AI Assistant features
- 429: Too many chats creation requests

---

### List Chats
**GET** `/Accounts/{accountId}/chats`

**Query Parameters:**
- `pageSize`: 1-1000, default: 25
- `skip`: default: 0
- `includeAgentJobChats`: boolean, default: false
- `sortBy`: default: "-CreateTime"

**Response 200:**
```json
{
  "results": [
    {
      "id": "uuid",
      "title": "Chat Title",
      "status": 1,
      "createTime": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

### Send Message
**POST** `/Accounts/{accountId}/chats/{chatId}/messages`

**Request Body:**
```json
{
  "sourceId": "string",
  "sourceType": 0,
  "content": "Your message here",
  "videoStartTime": "2024-01-01T00:00:00Z",
  "videoEndTime": "2024-01-01T00:00:00Z",
  "agentId": "uuid"
}
```

**Response 202:**
```json
{
  "messageId": "string",
  "chatId": "uuid"
}
```

---

### Get Chat Messages
**GET** `/Accounts/{accountId}/chats/{chatId}/messages`

**Query Parameters:**
- `limit`: 1-100, default: 25
- `sortOrder`: 0 (asc) or 1 (desc)
- `startAfter`: Message ID for pagination

**Response 200:**
```json
{
  "chatInfo": {
    "chatId": "uuid",
    "createTime": "2024-01-01T00:00:00Z"
  },
  "results": [
    {
      "messageId": "string",
      "chatId": "uuid",
      "role": 0,
      "content": {
        "type": 0,
        "text": "Message content"
      },
      "createTime": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

## Indexing

### Upload Video
**POST** `/Accounts/{accountId}/Videos`

Uploads and indexes a video.

**Query Parameters:**
- `name` (required): Video name
- `videoUrl` (optional): URL to video file
- `language` (optional): Language code (e.g., en-US, es-ES)
- `indexingPreset` (optional): Default, Basic, BasicAudio, BasicVideo
- `streamingPreset` (optional): Default, SingleBitrate, NoStreaming
- `excludedAI` (optional): Array of AI types to exclude
- `description` (optional): Video description
- `metadata` (optional): Custom metadata
- `callbackUrl` (optional): URL for notifications

**Form Data:**
- `fileName`: Binary video file

**Response 200:**
```json
{
  "id": "video-id",
  "name": "Video Name",
  "state": 1,
  "created": "2024-01-01T00:00:00Z"
}
```

**Error Responses:**
- 400: Invalid input or excluded AI options
- 507: Insufficient storage space

---

### Get Video Index
**GET** `/Accounts/{accountId}/Videos/{videoId}/Index`

**Query Parameters:**
- `language` (optional): Language for translation
- `includeStreamingUrls`: boolean, default: true

**Response 200:** Full video index with insights (see schema below)

---

### Re-Index Video
**PUT** `/Accounts/{accountId}/Videos/{videoId}/ReIndex`

**Query Parameters:**
- `excludedAI`: Array of AI types to exclude
- `indexingPreset`: Preset to use
- `sourceLanguage`: Language code
- `callbackUrl`: Notification URL

**Response 204:** Re-indexing started successfully

**Error Responses:**
- 400: Cannot re-index failed upload
- 409: Video already being indexed

---

## Videos

### List Videos
**GET** `/Accounts/{accountId}/Videos`

**Query Parameters:**
- `createdAfter`: ISO 8601 date-time
- `createdBefore`: ISO 8601 date-time
- `pageSize`: 1-1000, default: 25
- `skip`: default: 0
- `source`: Filter by camera ID or 'Upload'
- `sortBy`: Options: StartTime, EndTime, LastModified, DisplayName, Duration
- `insightType`: Filter by insight type ID
- `insightName`: Filter by insight name
- `tagId`, `tagValue`, `tagKey`: Filter by tags

**Response 200:**
```json
{
  "results": [
    {
      "id": "video-id",
      "name": "Video Name",
      "state": 2,
      "durationInSeconds": 120,
      "created": "2024-01-01T00:00:00Z",
      "thumbnailId": "uuid"
    }
  ],
  "nextPage": {
    "pageSize": 25,
    "skip": 0,
    "done": false
  }
}
```

---

### Get Video
**GET** `/Accounts/{accountId}/Videos/{videoId}`

**Response 200:**
```json
{
  "id": "video-id",
  "name": "Video Name",
  "state": 2,
  "processingProgress": "100%",
  "durationInSeconds": 120,
  "thumbnailId": "uuid",
  "startTime": "2024-01-01T00:00:00Z",
  "endTime": "2024-01-01T01:00:00Z",
  "source": "camera-id or Upload"
}
```

---

### Delete Video
**DELETE** `/Accounts/{accountId}/Videos/{videoId}`

**Response 204:** Video deleted successfully

---

### Get Video Captions
**GET** `/Accounts/{accountId}/Videos/{videoId}/Captions`

**Query Parameters:**
- `language`: Language code
- `format`: Vtt, Ttml, Srt, Txt, Csv (default: Vtt)

**Response 200:** Caption file content

---

### Get Video Streaming URL
**GET** `/Accounts/{accountId}/Videos/{videoId}/streaming-url`

**Response 200:**
```json
{
  "url": "https://streaming-url",
  "jwt": "token"
}
```

---

## Live Cameras

### Add Camera
**POST** `/Accounts/{accountId}/cameras`

**Request Body:**
```json
{
  "name": "Camera Name",
  "description": "Camera description",
  "presetId": "uuid",
  "isPinned": false,
  "liveStreamingEnabled": true,
  "recordingEnabled": true,
  "recordingsRetentionInHours": 720,
  "insightsRetentionInHours": 720,
  "rtspUrl": "rtsp://camera-url"
}
```

**Response 200:**
```json
{
  "id": "uuid",
  "name": "Camera Name",
  "status": 1,
  "liveStreamingEnabled": true,
  "recordingEnabled": true,
  "createTime": "2024-01-01T00:00:00Z"
}
```

---

### List Cameras
**GET** `/Accounts/{accountId}/cameras`

**Query Parameters:**
- `pageSize`: 1-1000, default: 25
- `skip`: default: 0
- `name`: Filter by name
- `presetIds`: Filter by preset IDs
- `isPinned`: Filter by pinned status
- `status`: Filter by camera status (0-3)
- `liveStreamingEnabled`: boolean
- `recordingEnabled`: boolean
- `sortBy`: default: "-liveStreamingEnabled,-recordingEnabled,name"

**Response 200:**
```json
{
  "results": [
    {
      "id": "uuid",
      "name": "Camera 1",
      "status": 1,
      "liveStreamingEnabled": true,
      "recordingEnabled": true
    }
  ]
}
```

---

### Update Camera
**PATCH** `/Accounts/{accountId}/cameras/{cameraId}`

**Request Body:** Same as Add Camera

---

### Remove Camera
**DELETE** `/Accounts/{accountId}/cameras/{cameraId}`

**Response 204:** Camera removed successfully

---

## Live Insights

### Get Live Insights by DateTime
**GET** `/Accounts/{accountId}/Cameras/{cameraId}/Insights`

**Query Parameters:**
- `dateTime`: ISO 8601 timestamp
- `includedInsightsTypes`: Array of insight types (format: "insightName-modelType")

**Response 200:**
```json
{
  "cameraId": "uuid",
  "height": 1080,
  "width": 1920,
  "start": "2024-01-01T00:00:00Z",
  "end": "2024-01-01T00:01:00Z",
  "detections": [
    {
      "insightName": "Vehicles",
      "modelType": "ObjectDetection",
      "id": "uuid",
      "instances": [
        {
          "x": 0.5,
          "y": 0.5,
          "width": 0.2,
          "height": 0.3,
          "confidence": 0.95,
          "start": "2024-01-01T00:00:05Z",
          "end": "2024-01-01T00:00:10Z"
        }
      ]
    }
  ]
}
```

---

## Custom Insights

### Create Custom Insight
**POST** `/Accounts/{accountId}/customInsights`

**Request Body:**
```json
{
  "insightName": "Custom Object",
  "modelType": 1,
  "description": "Description",
  "prompt": {
    "text": "Detect X in the image",
    "images": [
      {
        "name": "example.jpg",
        "id": "uuid"
      }
    ]
  }
}
```

**Response 200:**
```json
{
  "id": "uuid",
  "insightName": "Custom Object",
  "modelType": 1,
  "createTime": "2024-01-01T00:00:00Z"
}
```

---

### Add Images to Custom Insight
**POST** `/Accounts/{accountId}/customInsights/{insightId}/Images`

**Form Data:**
- `metadata`: JSON string
- `images`: Array of image files

**Response 200:**
```json
[
  {
    "name": "image1.jpg",
    "id": "uuid",
    "positiveExample": true,
    "error": null
  }
]
```

---

## Spatial Analysis Rules

### Create Spatial Analysis Rule
**POST** `/Accounts/{accountId}/cameras/{cameraId}/SpatialAnalysisRules`

**Request Body:**
```json
{
  "name": "Zone Entry",
  "description": "Detect entry into zone",
  "type": 0,
  "coordinates": [
    {"x": 0.1, "y": 0.1},
    {"x": 0.9, "y": 0.1},
    {"x": 0.9, "y": 0.9},
    {"x": 0.1, "y": 0.9}
  ],
  "direction": [
    {"x": 0.5, "y": 0.0},
    {"x": 0.5, "y": 1.0}
  ],
  "monitoredZoneId": "uuid",
  "active": true,
  "tagIds": ["uuid"]
}
```

**Response 200:** Spatial analysis rule created

**Error Responses:**
- 409: Cannot activate more than 10 rules on a camera

---

## Textual Summarization

### Summarize Video
**POST** `/Accounts/{accountId}/Videos/{videoId}/Summaries/Textual`

**Query Parameters:**
- `length`: Short, Medium, Long (default: Medium)
- `style`: Neutral, Casual, Formal (default: Neutral)
- `modelName`: Phi, Qwen (default: Phi)
- `includedFrames`: None, Keyframes (default: None)
- `eventsToFocusOn`: String describing events to highlight
- `summarizeFrom`: ISO 8601 datetime (for camera recordings)
- `summarizeUntil`: ISO 8601 datetime (for camera recordings)

**Response 202:** Accepted - Summary generation started

---

### Get Video Summary
**GET** `/Accounts/{accountId}/Videos/{videoId}/Summaries/Textual/{summaryId}`

**Response 200:**
```json
{
  "id": "uuid",
  "videoId": "video-id",
  "state": 2,
  "summary": "This video shows...",
  "createTime": "2024-01-01T00:00:00Z",
  "disclaimer": "AI-generated content"
}
```

---

## Search

### Search Videos
**POST** `/Accounts/{accountId}/videos/search`

Natural language search across video content.

**Request Body:**
```json
{
  "query": "Find videos with people wearing red",
  "filters": {
    "source": ["camera-id-1"],
    "insightName": ["People"],
    "createdAfter": "2024-01-01T00:00:00Z",
    "createdBefore": "2024-12-31T23:59:59Z",
    "tagValue": ["important"]
  }
}
```

**Response 200:**
```json
{
  "results": [
    {
      "videoId": "video-id",
      "start": 10.5,
      "end": 25.3,
      "confidence": 0.89,
      "detectedAis": [
        {
          "insightName": "People",
          "modelType": "ObjectDetection"
        }
      ],
      "thumbnailBase64": "base64-string"
    }
  ]
}
```

---

## Tags

### Create Tag
**POST** `/Accounts/{accountId}/tags`

**Request Body:**
```json
{
  "key": "category",
  "value": "important"
}
```

**Response 200:**
```json
{
  "id": "uuid",
  "key": "category",
  "value": "important",
  "createTime": "2024-01-01T00:00:00Z"
}
```

---

### List Tags
**GET** `/Accounts/{accountId}/tags`

**Query Parameters:**
- `key`: Filter by key
- `value`: Filter by value
- `createdBefore`, `createdAfter`: Date filters
- `pageSize`, `skip`, `sortBy`

---

## Response Codes

### Success
- **200** OK - Request successful
- **201** Created - Resource created
- **202** Accepted - Request accepted for processing
- **204** No Content - Successful deletion
- **303** See Other - Redirect (job completed)

### Client Errors
- **400** Bad Request - Invalid input
- **401** Unauthorized - Authentication required
- **403** Forbidden - Insufficient permissions
- **404** Not Found - Resource not found
- **409** Conflict - Resource conflict

### Server Errors
- **429** Too Many Requests - Rate limit exceeded
- **500** Internal Server Error
- **507** Insufficient Storage

---

## Common Data Types

### TimeSpan Format
```
"00:01:30.500"  // 1 minute, 30.5 seconds
```

### DateTime Format (ISO 8601)
```
"2024-01-01T12:00:00Z"
```

### UUID Format
```
"550e8400-e29b-41d4-a716-446655440000"
```

---

## Rate Limiting

API calls are subject to rate limiting. Respect retry-after headers on 429 responses.

---

## Pagination

Most list endpoints support pagination:
- `pageSize`: Number of items per page (1-1000)
- `skip`: Number of items to skip
- Response includes `nextPage` object with pagination info

---

## Notes

1. All timestamps use ISO 8601 format
2. UUIDs are used for resource identifiers
3. Bearer tokens expire and must be refreshed
4. Maximum upload sizes and duration limits apply per account tier
5. Some features require specific permissions or limited access approvals

---

*For complete schema definitions and additional endpoints, refer to the OpenAPI specification file.*
