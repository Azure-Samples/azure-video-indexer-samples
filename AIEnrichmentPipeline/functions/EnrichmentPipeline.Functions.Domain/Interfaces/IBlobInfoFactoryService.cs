using System;
using EnrichmentPipeline.Functions.Domain.Models;

namespace EnrichmentPipeline.Functions.Domain.Interfaces
{
    /// <summary>
    /// Service interface to create BlobInfo objects.
    /// </summary>
    public interface IBlobInfoFactoryService
    {
        /// <summary>
        /// Create a populated BlobInfo class object.
        /// </summary>
        /// <param name="uri">The uri represented in the BlobInfo.</param>
        /// <param name="name">The name of the file identified by the uri.</param>
        /// <param name="correlationId">Correlation Id to use for the BlobInfo.</param>
        /// <returns>Created BlobInfo object.</returns>
        BlobInfo CreateBlobInfo(Uri uri, string name, Guid correlationId);

        /// <summary>
        /// Generate a guid to be used as the Correlation ID.
        /// </summary>
        /// <returns>the correlation id string.</returns>
        Guid CreateCorrelationId();
    }
}
