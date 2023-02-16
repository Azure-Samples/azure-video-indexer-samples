package eventprocessor;

import com.azure.identity.*;
import com.azure.messaging.eventhubs.EventProcessorClient;
import com.azure.messaging.eventhubs.EventProcessorClientBuilder;
import eventprocessor.store.SimpleCheckpointStore;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

/**
 * The EventProcessor Sample is take from <a href="https://github.com/Azure/azure-sdk-for-java/blob/main/sdk/eventhubs/azure-messaging-eventhubs/README.md#consume-events-using-an-eventprocessorclient">...</a>
 * For more information about Azure Event Hubs SDK For Java visit : <a href="https://github.com/Azure/azure-sdk-for-java/blob/main/sdk/eventhubs/azure-messaging-eventhubs/README.md#azure-event-hubs-client-library-for-java">...</a>
 */
public class VideoIndexerEventProcessorApp {
    // The fully qualified namespace for the Event Hubs instance. This is likely to be similar to:
    // {your-namespace}.servicebus.windows.net
    private static final String eventHubsFqns = "ts-poc-eh.servicebus.windows.net";
    private static final String eventHubName = "indexing-events";
    private static final String ConsumerGroupName = "events";

    public static void main(String[] args) throws InterruptedException {

        System.out.println("Video Indexer Event Processor Sample");
        System.out.println("=====================================");

        Semaphore semaphore = new Semaphore(0);
        ManagedIdentityCredential managedIdentityCredential = new ManagedIdentityCredentialBuilder().build();
        AzureCliCredential cliCredential = new AzureCliCredentialBuilder().build();

        //Using ChainedTokenCredentials can help in customize the credentials considered when authenticating
        //https://azuresdkdocs.blob.core.windows.net/$web/java/azure-identity/1.8.0/index.html
        ChainedTokenCredential credential = new ChainedTokenCredentialBuilder()
                .addLast(managedIdentityCredential)
                .addLast(cliCredential).build();

        VideoIndexerEventHandler handler = new VideoIndexerEventHandler();
        System.out.println("Create Event Processor Client on namespace " + eventHubsFqns);

        /// Creating Event Processor Client using DefaultAzureCredentials
        EventProcessorClient eventProcessorClient = new EventProcessorClientBuilder()
                .consumerGroup(ConsumerGroupName)
                .credential(eventHubsFqns, eventHubName, credential)
                .checkpointStore(new SimpleCheckpointStore())
                .processEvent(handler::onEvent)
                .processError(handler::onError)
                .buildEventProcessorClient();

// This will start the processor. It will start processing events from all partitions.
        System.out.println("Start listening for incoming events");
        eventProcessorClient.start();

// (for demo purposes only - prevent closing the app for 20 min in order to receive events)
        System.out.println("Pending Event processing.......");
        semaphore.tryAcquire(200, TimeUnit.MINUTES);

        System.out.println("Stopping Event Processor");
// This will stop processing events.
        eventProcessorClient.stop();

    }

}

