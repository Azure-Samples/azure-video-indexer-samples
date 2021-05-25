using System;
using Azure.Messaging.ServiceBus;
using EnrichmentPipeline.Functions.WorkflowTrigger.Interfaces;

namespace EnrichmentPipeline.Functions.WorkflowTrigger.Services
{
    /// <inheritdoc/>
    public class ServiceBusClientService : IServiceBusClientService
    {
        /// <inheritdoc/>
        public ServiceBusClient CreateServiceBusClient(string connectionString)
        {
            if (connectionString == null)
            {
                throw new ArgumentNullException(nameof(connectionString));
            }

            return new ServiceBusClient(connectionString);
        }
    }
}
