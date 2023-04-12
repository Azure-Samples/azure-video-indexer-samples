package eventprocessor;

import com.azure.messaging.eventhubs.models.ErrorContext;
import com.azure.messaging.eventhubs.models.EventContext;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import eventprocessor.model.IndexEvent;
import eventprocessor.model.IndexEventRecord;

import java.text.MessageFormat;
import java.util.Arrays;
import java.util.Objects;

public class VideoIndexerEventHandler {
    /**
     * Event Categories
     * there are 2 event categories : IndexingLogs - for the indexing operations, and AuditLogs - for auditing purposes.
     */
    private static final String INDEXING_LOGS_CATEGORY = "IndexingLogs";
    private static final String AUDIT_CATEGORY = "Audit";


    private final Gson gson;

    public VideoIndexerEventHandler() {
        gson = new GsonBuilder().setPrettyPrinting().create();
    }

    /**
     * Event Hub Message Handler
     *
     * @param eventContext - event Context from the event hubs
     */
    public void onEvent(EventContext eventContext) {
        //Print general information about the event hub metadata
        System.out.println("Partition id = " + eventContext.getPartitionContext().getPartitionId()
                + " and " + "sequence number of event = " + eventContext.getEventData().getSequenceNumber());

        try {
            String eventString = eventContext.getEventData().getBodyAsString();
            IndexEvent indexEvent = gson.fromJson(eventString, IndexEvent.class);

            //Fetch only events that are "Indexing Logs" for this demo purposes
            Arrays.stream(indexEvent.records)
                    .filter(x -> Objects.equals(x.category, INDEXING_LOGS_CATEGORY))
                    .forEach(this::processEvent);
        } catch (Exception ex) {
            System.out.println(ex.getMessage());
        }
    }

    /**
     * Dummy Event Processor Logic - only prints the fields received from Event Hubs
     * @param evt - IndexEventRecord
     * Reference: <a href="https://learn.microsoft.com/en-us/azure/azure-video-indexer/monitor-video-indexer-data-reference">...</a>
     */
    private void processEvent(IndexEventRecord evt)
    {
        var videoId = evt.properties.videoId;
        var fileName = evt.properties.indexing.Filename;
        var retentionInDays = evt.properties.indexing.RetentionInDays;
        var externalId = evt.properties.indexing.ExternalId;
        var resultType = evt.resultType;

        var operationName= evt.operationName;
        //Possible Operation Name Values: [ UploadStarted, UploadFinished, IndexingStarted , IndexingFinished, ReindexingStarted, ReindexingFinished ]

        System.out.println(MessageFormat.format("Index Video Event Received. Operation: {0}, VideoId: {1}, File: {2}, ExternalId: {3}, RetentionInDays: {4}, Result: {5}",
                operationName,
                videoId,
                fileName,
                externalId,
                retentionInDays,
                resultType));
    }

    /**
     * Placehold to hanlde event processing errors
     *
     * @param errorContext : Error context from the Event Hubs
     */
    public void onError(ErrorContext errorContext) {
        System.out.println("Error occurred while processing events " + errorContext.getThrowable().getMessage());
    }
}
