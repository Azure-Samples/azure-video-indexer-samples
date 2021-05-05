using Azure.Messaging.ServiceBus;

namespace EnrichmentPipeline.Functions.WorkflowTrigger.Interfaces
{
    /// <summary>
    /// Service to create a new service bus client.
    /// </summary>
    public interface IServiceBusClientService
    {
        /// <summary>
        /// Creates a new service bus client.
        /// </summary>
        /// <param name="connectionString">Connection string to create the client from.</param>
        /// <returns>ServiceBusClient.</returns>
        ServiceBusClient CreateServiceBusClient(string connectionString);
    }
}
