package eventprocessor;

import com.azure.messaging.eventhubs.models.ErrorContext;
import com.azure.messaging.eventhubs.models.EventContext;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import eventprocessor.model.IndexEvent;

import java.text.MessageFormat;

public class VideoIndexerEventHandler {
    private static final String UPLOAD_STARTED = "UploadStarted";
    private static final String UPLOAD_FINISHED = "UploadFinished";
    private static final String INDEXING_STARTED = "IndexingStarted";
    private static final String INDEXING_FINISHED = "IndexingFinished";
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
        System.out.println("Partition id = " + eventContext.getPartitionContext().getPartitionId() + " and " + "sequence number of event = " + eventContext.getEventData().getSequenceNumber());

        try {
            String eventString = eventContext.getEventData().getBodyAsString();
            IndexEvent indexEvent = gson.fromJson(eventString, IndexEvent.class);
            switch (indexEvent.operationName) {
                case UPLOAD_STARTED ->
                        System.out.println(MessageFormat.format("Upload operation with video Id {0} has started. Result = ", indexEvent.properties.videoId, indexEvent.resultType));
                case UPLOAD_FINISHED ->
                        System.out.println(MessageFormat.format("Upload operation with video Id {0} has finished. Result = ", indexEvent.properties.videoId, indexEvent.resultType));
                case INDEXING_STARTED ->
                        System.out.println(MessageFormat.format("Indexing operation with video Id {0} has started. Result = ", indexEvent.properties.videoId, indexEvent.resultType));
                case INDEXING_FINISHED ->
                        System.out.println(MessageFormat.format("Indexing operation with video Id {0} has finished. Result = ", indexEvent.properties.videoId, indexEvent.resultType));
                default -> System.out.println("Unknown Event " + eventString);
            }
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
