using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using EnrichmentPipeline.Functions.Domain.Models;

namespace EnrichmentPipeline.Functions.WorkflowTrigger.Interfaces
{
    /// <summary>
    /// Client for interaction with the ServiceBus SDK.
    /// </summary>
    public interface IServiceBusService
    {
        /// <summary>
        /// Send a service bus message congianing the provided BlobInfo.
        /// </summary>
        /// <param name="blobInfo">The BlobInfo to send as a service bus message.</param>
        /// <returns>A <see cref="Task"/> representing the asynchronous operation.</returns>
        Task SubmitBlobInfoToServiceBus(BlobInfo blobInfo);
    }
}
