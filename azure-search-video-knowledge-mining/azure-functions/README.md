# Azure Cognitive Search - Video Knowledge Mining

## start-video-indexing
Trigger: Azure Blob Storage file upload  
Output: Start Azure Video Indexing to extract insights from the video

## video-indexer-callback
Trigger: Azure Video Indexer callback  
Output: Azure Cognitive Search index populated with video insights extracted from Azure Video Indexer


## Function App Settings
| App Setting         | Value                           | Note                                                             |
|---------------------|---------------------------------|------------------------------------------------------------------|
| AzureWebJobsStorage | FUNCTION_BLOB_STORAGE_CONNECTION_STRING | Azure Blob Storage connection string to store Function artifacts |  
| FUNCTIONS_WORKER_RUNTIME | python  |  
| blob_container | BLOB_CONTAINER | Azure Blob Storage Container  |  
| blob_account | BLOB_ACCOUNT | Azure Blob Storage Account    |  
| blob_key | BLOB_KEY | Azure Blob Storage Key  |  
| blob_container_source | BLOB_CONTAINER_VIDEO_DROP | Azure Blob Storage Container for Videos to be indexed  |  
| DEBUG | false | Enable to log information true / false  |  
| entities | transcript,ocr,keywords,topics,faces, labels,brands,namedLocations,namedPeople | Entities you want to extract from videos as insights and push to Azure Cognitive Search  |  
| function_url | CALLBACK_URL_VIDEO_INDEXER_PROCESSING | Azure Function to be called when the Azure Video Indexer complete processing a video  |  
| search_account | SEARCH_ACCOUNT | Azure Cognitive Search Account|  
| search_index | SEARCH_INDEX | Azure Cognitive Search Index  |  
| search_api_key | SEARCH_API_KEY | Azure Cognitive Search Account Key|  
| search_api_version | 2019-05-06 | Azure Cognitive Search API Version|  
| video_indexer_account_id | VIDEO_INDEXER_ACCOUNT_ID | Azure Video Indexer Account Id|  
| video_indexer_api_key | VIDEO_INDEXER_API_KEY | Azure Video Indexer Account Key|  
| video_indexer_endpoint | https://api.videoindexer.ai | Azure Video Indexer endpoint|  
| video_indexer_location | VIDEO_INDEXER_LOCATION | Azure Video Indexer location e.g. westeurope|  
| video_indexer_location_url_prefix | VIDEO_INDEXER_LOCATION_URL_PREFIX | Azure Video Indexer Location url prefix e.g. www for trial, weu for westeurope, etc. You can find your prefix in the Video Indexer interface -> Embed video|  
| videoknowledgemining_STORAGE | BLOB_STORAGE_CONNECTION_STRING_VIDEO_DROP | Azure Blob Storage connection string to account with videos  |  

