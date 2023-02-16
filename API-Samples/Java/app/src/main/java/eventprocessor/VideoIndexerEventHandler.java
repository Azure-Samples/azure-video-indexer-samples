package eventprocessor;

import com.azure.messaging.eventhubs.models.ErrorContext;
import com.azure.messaging.eventhubs.models.EventContext;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import eventprocessor.model.IndexEvent;

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

    /**
     * Indexing Logs Events
     * The Events that can appear on the OperationName field when the category is "IndexingLogs"
     */
    private static final String UPLOAD_STARTED = "UploadStarted";
    private static final String UPLOAD_FINISHED = "UploadFinished";
    private static final String INDEXING_STARTED = "IndexingStarted";
    private static final String INDEXING_FINISHED = "IndexingFinished";
    private static final String REINDEX_STARTED = "ReindexingStarted";
    private static final String REINDEX_FINISHED = "ReindexingFinished";



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
                    .filter(x-> Objects.equals(x.category, INDEXING_LOGS_CATEGORY))
                    .forEach(evt -> {
                        var videoId = evt.properties.videoId;
                        var fileName = evt.properties.indexing.Filename;
                        var resultType = evt.resultType;
                        switch (evt.operationName) {
                            case UPLOAD_STARTED ->
                                    System.out.println(MessageFormat.format("Upload operation with video Id {0} has started on File = {1} . Result = {2}",
                                            videoId, fileName, resultType));
                            case UPLOAD_FINISHED ->
                                    System.out.println(MessageFormat.format("Upload operation with video Id {0} has finished on File = {1} . Result = {2}",
                                            videoId, fileName, resultType));
                            case INDEXING_STARTED ->
                                    System.out.println(MessageFormat.format("Indexing operation with video Id {0} has started on File = {1} . Result = {2}",
                                            videoId, fileName, resultType));
                            case INDEXING_FINISHED ->
                                    System.out.println(MessageFormat.format("Indexing operation with video Id {0} has finished on File = {1} . Result = {2}",
                                            videoId, fileName, resultType));
                            case REINDEX_STARTED ->
                                    System.out.println(MessageFormat.format("Re-Indexing operation with video Id {0} has started on File = {1} . Result = {2}",
                                            videoId, fileName, resultType));
                            case REINDEX_FINISHED ->
                                    System.out.println(MessageFormat.format("Re-Indexing operation with video Id {0} has finished on File = {1} . Result = {2}",
                                            videoId, fileName, resultType));
                            default -> System.out.println("Unknown Event " + eventString);
                        }
                    });
        } catch (Exception ex) {
            System.out.println(ex.getMessage());
        }
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
