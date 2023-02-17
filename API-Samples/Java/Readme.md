# Video Indexer API Samples For Java

This Azure Video Indexer Java Samples document contains 2 Java Console Application folders, located under the src/main/java folder. They are:

1. apisamples: 

It demonstrates the VideoIndexer API calls to perform the following:  
  - Get Account Access Token
  - Upload a video ( with/without streaming capabilities)
  - Wait For an Index operation to finish using Polling Mechanism
  - Get Video Results 
  - Delete a Video and all its related assets

2. eventProcessor: 

It demonstrates the usage of Event Hubs processor mechanism to retreive indexing events and to be notified without polling on index completion events.

## Getting started

### Prerequisites

- A [Java Development Kit (JDK)][jdk_link], version 11 or later.
- [Gradle][gradle]
- Microsoft Azure subscription
  - You can create a free account at: [https://azure.microsoft.com](https://azure.microsoft.com)
- Azure Video Indexer instance
  - Step-by-step guide for [creating an Video Indexer Account using Terraform][vi_terrafor_create]
- Azure Event Hubs instance
  - Step-by-step guide for [creating an Event Hub using the Azure Portal][event_hubs_create]


#### Library Dependencies
The samples depends on the following [maven repository libraries][maven_repo]

```java
    dependencies {
        implementation 'com.google.guava:guava:31.1-jre'
        implementation 'com.google.code.gson:gson:2.10.1'
        implementation 'com.azure:azure-identity:1.8.0'
        implementation 'com.azure:azure-messaging-eventhubs:5.15.2'
        implementation 'com.azure:azure-messaging-eventhubs-checkpointstore-blob:1.16.3'
    }
```


## Samples

### API Rest Samples

The Samples contain a [`VideoIndexerClient`][VideoIndexerClient] which is a REST wrapper to perform the http calls.
It uses an Azure ARM Token to retreive the Video Indexer Account Token which is valid for 1 hour
to perform Video Indexer API Calls. The caller is responsible to refresh that token after it times out. 
To Upload Video, the Client uses the Upload Video URL, with the following url Parameters: 

```java readme-sample-publishEvents
        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("name", videoName);
        map.put("description", "video_description");
        map.put("privacy", "private");
        map.put("partition", "partition");
        map.put("videoUrl", videoUrl);
        map.put("streamingPreset","NoStreaming");
```

Note that when `streamingPreset` is the to `NoStreaming` the index operation skips the Azure Media Services Streaming endpoint, which
expedites the completion of the indexing.

The sample uses Busy Wait loop to Poll on completion status of the indexed videos.

#### Consuming Video Indexer Events from Event Hubs

Developers can consume the Video Indexer Operations from an Event Hubs integration by following the pattern described on the 
[Collection and Route][vi_collection_route] Section of Video Indexer Documentation.

Video Indexer Diagnostic Settings allows developer to consume the following Event Types:
- Audit Events
- Indexing Log Events

The sample uses [`EventProcessorClient`][EventProcessorClient] that process incoming events from the Event Hub and handles them according to the Operation Name field.
Event that was configured at the Diagnostic Settings of the Video Indexer Account.

The following events from the Indexing Logs Category are available:

```java indexing-logs-category
    String UPLOAD_STARTED = "UploadStarted";
    String UPLOAD_FINISHED = "UploadFinished";
    String INDEXING_STARTED = "IndexingStarted";
    String INDEXING_FINISHED = "IndexingFinished";
    String REINDEX_STARTED = "ReindexingStarted";
    String REINDEX_FINISHED = "ReindexingFinished";
```

The sample also contains an example on the [event schema][vi_eh_schema] for the Video Indexing /Audit Logs.

## Next steps

1. Review the [Azure Video Indexer Docs](https://learn.microsoft.com/en-us/azure/azure-video-indexer)
2. Review and interact with the [Video Indexer API][vi_api]
3. Create an Account using Terraform or ARM/Bicep [Deployment Tutorial][vi_deploy] and run those samples with the created account.



<!-- Links -->
[event_hubs_create]: https://docs.microsoft.com/azure/event-hubs/event-hubs-create
[vi_terrafor_create]: https://github.com/Azure-Samples/media-services-video-indexer/tree/master/Deploy-Samples/Terraform
[VideoIndexerClient]: https://github.com/Azure-Samples/media-services-video-indexer/blob/master/API-Samples/Java/app/src/main/java/apisamples/VideoIndexerClient.java
[vi_collection_route]: https://learn.microsoft.com/en-us/azure/azure-video-indexer/monitor-video-indexer#collection-and-routing
[EventProcessorClient]: https://github.com/Azure/azure-sdk-for-java/blob/main/sdk/eventhubs/azure-messaging-eventhubs/README.md#consume-events-using-an-eventprocessorclient
[jdk_link]: https://jdk.java.net/11/
[gradle]: https://gradle.org/
[maven_repo]: https://mvnrepository.com/
[vi_api]: https://api-portal.videoindexer.ai/
[vi_deploy]: https://github.com/Azure-Samples/media-services-video-indexer/tree/master/Deploy-Samples
[vi_eh_schema]: https://github.com/Azure-Samples/media-services-video-indexer/blob/master/API-Samples/Java/app/src/main/java/eventprocessor/sample/sample.json
