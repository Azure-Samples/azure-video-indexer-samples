# Video Indexer Arc API Documentation

This documentation provides curl commands for interacting with the Video Indexer Arc API based on the OpenAPI specification.

## Prerequisites

### Authentication Setup

Before using any API endpoints, you need to obtain an access token. The token is obtained through Azure ARM API:

```bash
# Set your environment variables
export BASE_ADDRESS="<your arc extension base address>"
export SUBSCRIPTION="<your azure subscription id>"
export RG="<your video indexer account resource group>"
export VI_ACCOUNT_NAME="<your video indexer account name>"
export ACCOUNT_ID="<your video indexer account id>"

# Get Azure token
AZ_TOKEN=$(az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv)

# Get extension access token - replace with your Arc environment resource group and cluster details
export ARC_RESOURCE_GROUP="<your arc environment resource group>"
export ARC_CLUSTER_NAME="<your arc connected cluster name>"
export ARC_EXTENSION_NAME="<your arc extension name>"

ARC_ENV_ID="/subscriptions/$SUBSCRIPTION/resourceGroups/$ARC_RESOURCE_GROUP/providers/Microsoft.Kubernetes/connectedClusters/$ARC_CLUSTER_NAME/Providers/Microsoft.KubernetesConfiguration/extensions/$ARC_EXTENSION_NAME"

VI_ARC_DEV_TOKEN=$(curl -s -k -X POST "https://management.azure.com/subscriptions/$SUBSCRIPTION/resourcegroups/$RG/providers/Microsoft.VideoIndexer/accounts/$VI_ACCOUNT_NAME/generateExtensionAccessToken?api-version=2023-06-02-preview" \
    -H "Authorization: Bearer $AZ_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"permissionType\": \"Contributor\",
        \"scope\": \"Account\",
        \"extensionId\": \"$ARC_ENV_ID\"
    }" | jq -r '.accessToken')
```

## API Endpoints

### Extensions

#### Get Extension Details
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/extension" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### General

#### Get General Info About the Extension
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/info" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Videos

#### Upload Video
```bash
# Upload a video file
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -F "fileName=@/path/to/your/video.mp4" \
  -F "name=My Video" \
  -F "description=Video description" \
  -F "language=en-US" \
  -F "indexingPreset=Default" \
  -F "streamingPreset=Default"
```

#### Upload Video from URL
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos?name=My%20Video&videoUrl=https://example.com/video.mp4&language=en-US&indexingPreset=Default&streamingPreset=Default" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### List Videos
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### List Videos with Filters
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos?pageSize=50&skip=0&sortBy=-StartTime&source=Upload" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Delete Video
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Delete Video Source File
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/SourceFile" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Video Indexing

#### Get Video Index
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Index" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Index with Language
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Index?language=en-US&includeStreamingUrls=true" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Re-Index Video
```bash
curl -s -k -v -X 'PUT' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/ReIndex" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Re-Index Video with Parameters
```bash
curl -s -k -v -X 'PUT' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/ReIndex?sourceLanguage=en-US&indexingPreset=Default&streamingPreset=Default" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Update Video Index
```bash
curl -s -k -v -X 'PATCH' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Index" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json-patch+json' \
  -d '[
    {
      "op": "replace",
      "path": "/videos/0/insights/transcript/0/text",
      "value": "Updated transcript text"
    }
  ]'
```

#### Update Video Metadata
```bash
curl -s -k -v -X 'PUT' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Index" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Updated Video Name",
    "metadata": "Updated metadata",
    "startTime": "2023-01-01T00:00:00Z"
  }'
```

### Video Streaming and Media

#### Get Video Streaming URL
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/streaming-url" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Download Video Streaming Manifest
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/streaming-manifest/{manifestFile}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Download Video Streaming File
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/streaming-file/{fileName}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Captions
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Captions?language=en-US&format=Vtt" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Thumbnail
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Thumbnails/{thumbnailId}?format=Jpeg" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Sprite
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Sprite?type=KeyFrames&pageIndex=0" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Frames File Paths
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/FramesFilePaths?pageSize=1000&skip=0" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Live Cameras

#### Add Camera
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Test Camera",
    "description": "Test camera description",
    "rtspUrl": "rtsp://example.com/stream",
    "liveStreamingEnabled": true,
    "recordingEnabled": true,
    "isPinned": true,
    "presetId": "5011e17b-294e-46a9-8d91-5ad9f5488ba4",
    "recordingsRetentionInHours": 168,
    "insightsRetentionInHours": 168
  }'
```

#### List Cameras
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### List Cameras with Filters
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras?pageSize=25&skip=0&sortBy=-liveStreamingEnabled,-recordingEnabled,name&liveStreamingEnabled=true&recordingEnabled=true" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Camera
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Update Camera
```bash
curl -s -k -v -X 'PATCH' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Updated Camera Name",
    "description": "Updated description",
    "liveStreamingEnabled": false,
    "recordingEnabled": true
  }'
```

#### Delete Camera
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Camera Thumbnail
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/Thumbnail" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Live Streaming

#### Get Live Streaming Manifest
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/streaming-manifest/{manifestFile}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Download Live Streaming File
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/streaming-file/{fileName}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Live Insights

#### Get Live Insights by DateTime
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Cameras/{cameraId}/Insights?dateTime=2023-10-05T14:48:00Z" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Live Insights with Filters
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Cameras/{cameraId}/Insights?dateTime=2023-10-05T14:48:00Z&includedInsightsTypes=Vehicles-ObjectDetection,People-ObjectDetection" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Recorded Insights

#### Get Recorded Insights Page by Page Number
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/liveInsights/Pages/{pageNumber}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Recorded Insights Page by Time
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/liveInsights/Pages?time=120.5" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Live Presets

#### Create Live Preset
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Presets" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "My Preset",
    "insightTypes": [
      {
        "id": "00000000-0000-0000-0000-000000000001",
        "configuration": {}
      }
    ]
  }'
```

#### List Live Presets
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Presets?pageSize=25&skip=0" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Live Preset
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Presets/{presetId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Update Live Preset
```bash
curl -s -k -v -X 'PATCH' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Presets/{presetId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Updated Preset Name",
    "insightTypes": [
      {
        "id": "00000000-0000-0000-0000-000000000001",
        "configuration": {}
      }
    ]
  }'
```

#### Delete Live Preset
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Presets/{presetId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Built-in Insight Types

#### List Live Built-in Insight Types
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/builtInInsightTypes" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### List Insight Types
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/insightTypes?pageSize=25&skip=0&detectedOnly=true" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Custom Insights

#### Create Custom Insight
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "insightName": "My Custom Insight",
    "modelType": 0,
    "description": "Custom insight description",
    "prompt": {
      "text": "Detect custom objects",
      "color": 0,
      "images": []
    }
  }'
```

#### List Custom Insights
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights?pageSize=25&skip=0&sortBy=-LastUpdateTime" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Custom Insight
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights/{insightId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Update Custom Insight
```bash
curl -s -k -v -X 'PUT' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights/{insightId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "insightName": "Updated Custom Insight",
    "modelType": 0,
    "description": "Updated description",
    "prompt": {
      "text": "Updated prompt text",
      "color": 1,
      "images": []
    }
  }'
```

#### Delete Custom Insight
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights/{insightId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Add Image to Custom Insight
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights/{insightId}/Images?imageName=sample_image" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -F "image=@/path/to/image.jpg"
```

#### Get Image from Custom Insight
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights/{insightId}/Images/{imageId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Delete Image from Custom Insight
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/customInsights/{insightId}/Images/{imageId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Spatial Analysis Rules

#### Create Spatial Analysis Rule
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/SpatialAnalysisRules" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Line Crossing Rule",
    "description": "Detects line crossing",
    "type": 1,
    "coordinates": [
      {"x": 0.1, "y": 0.1},
      {"x": 0.9, "y": 0.9}
    ],
    "direction": [
      {"x": 1.0, "y": 0.0}
    ],
    "active": true,
    "tagIds": []
  }'
```

#### List Spatial Analysis Rules
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/SpatialAnalysisRules?active=true&sortBy=createTime" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Spatial Analysis Rule
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/SpatialAnalysisRules/{spatialAnalysisRuleId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Update Spatial Analysis Rule
```bash
curl -s -k -v -X 'PATCH' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/SpatialAnalysisRules/{spatialAnalysisRuleId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Updated Rule Name",
    "active": false
  }'
```

#### Delete Spatial Analysis Rule
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/cameras/{cameraId}/SpatialAnalysisRules/{spatialAnalysisRuleId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Tags

#### Create Tag
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/tags" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "key": "Environment",
    "value": "Production"
  }'
```

#### List Tags
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/tags?pageSize=25&skip=0&sortBy=key,value" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Tag
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/tags/{tagId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Delete Tag
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/tags/{tagId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Add Tag to Video
```bash
curl -s -k -v -X 'PUT' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/tags/{tagId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Remove Tag from Video
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/tags/{tagId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Tags
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/tags" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Textual Summarization

#### Generate Video Summary
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Summaries/Textual?length=Medium&style=Neutral&modelName=Phi&includedFrames=None" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Generate Video Summary with Custom Parameters
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Summaries/Textual?length=Long&style=Formal&modelName=Qwen&includedFrames=Keyframes&eventsToFocusOn=Vehicle%20detection,Person%20movement" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### List Video Summaries
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Summaries/Textual?pageNumber=0&pageSize=20" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Summary by ID
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Summaries/Textual/{summaryId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Delete Video Summary
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Summaries/Textual/{summaryId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Translation

#### Translate Video Index
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/Translate?language=es-ES" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Visual Search (RAG)

#### Search Videos using Natural Language
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/videos/search" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "Show me videos with cars and people",
    "filters": {
      "source": ["Upload"],
      "insightName": ["Vehicles", "People"],
      "createdAfter": "2023-01-01T00:00:00Z",
      "createdBefore": "2023-12-31T23:59:59Z",
      "tagValue": ["production"]
    }
  }'
```

### Prompt Content

#### Create Prompt Content
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/PromptContent?modelName=Phi3&promptStyle=Full" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Prompt Content
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/PromptContent" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Jobs

#### Get Job Status
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Jobs/{jobId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Language Models and Support

#### Get Language Models
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/LanguageModels" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Supported Languages
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/SupportedLanguages" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Supported AIs
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/SupportedAIs?indexingPreset=Default" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Media Server

#### Get Media Server Config
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/mediaServer/config" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Monitored Zones

#### Create Monitored Zone
```bash
curl -s -k -v -X 'POST' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/monitoredZones" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Parking Lot Zone",
    "description": "Main parking lot monitoring zone"
  }'
```

#### List Monitored Zones
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/monitoredZones?pageSize=25&skip=0" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Monitored Zone
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/monitoredZones/{monitoredZoneId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Update Monitored Zone
```bash
curl -s -k -v -X 'PATCH' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/monitoredZones/{monitoredZoneId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Updated Zone Name",
    "description": "Updated zone description"
  }'
```

#### Delete Monitored Zone
```bash
curl -s -k -v -X 'DELETE' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/monitoredZones/{monitoredZoneId}" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

### Miscellaneous

#### Get Video Network Info
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/VideoInfo?videoUrl=https://example.com/video.mp4" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

#### Get Video Insight Types
```bash
curl -s -k -v -X 'GET' --http1.1 "$BASE_ADDRESS/Accounts/$ACCOUNT_ID/Videos/{videoId}/insightTypes" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $VI_ARC_DEV_TOKEN" \
  -H 'Content-Type: application/json'
```

## Notes

1. Replace `{videoId}`, `{cameraId}`, `{tagId}`, etc. with actual IDs from your responses
2. The `$VI_ARC_DEV_TOKEN` variable should contain your access token obtained from the authentication setup
3. All requests use the `-k` flag to ignore SSL certificate errors (useful for development environments)
4. The `-v` flag enables verbose output for debugging
5. Response format is JSON unless otherwise specified
6. Some endpoints support query parameters for pagination, filtering, and sorting
7. File uploads use `multipart/form-data` encoding
8. The `--http1.1` flag ensures HTTP/1.1 compatibility

## Common Query Parameters

- `pageSize`: Number of items per page (default: 25, max: 1000)
- `skip`: Number of items to skip for pagination (default: 0)
- `sortBy`: Sorting criteria (use `-` prefix for descending order)
- `language`: Language code (e.g., `en-US`, `es-ES`)
- `format`: Output format for downloads (e.g., `Vtt`, `Jpeg`)

## Error Handling

The API returns standard HTTP status codes:
- `200`: Success
- `202`: Accepted (for async operations)
- `400`: Bad Request
- `401`: Unauthorized
- `404`: Not Found
- `409`: Conflict
- `500`: Internal Server Error

Error responses include a JSON object with error details and message.
