using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Primitives;
using EnrichmentPipeline.Functions.Domain.Models;
using EnrichmentPipeline.Functions.Domain.Constants;

namespace EnrichmentPipeline.Functions.Domain.Extensions
{
    /// <summary>
    /// A location to define extension methods.
    /// </summary>
    public static class Extensions
    {
        /// <summary>
        /// Extension method to wrap the creation of the correlation Id scope.
        /// </summary>
        /// <param name="logger">The ILogger to act on.</param>
        /// <param name="correlationId">The correlation Id guid.</param>
        /// <returns>IDisposable defining the scope.</returns>
        public static IDisposable UseCorrelationScope(this ILogger logger, Guid correlationId)
        {
            return logger.UseCorrelationScope(correlationId.ToString());
        }

        /// <summary>
        /// Extension method to wrap the creation of the correlation Id scope.
        /// </summary>
        /// <param name="logger">The ILogger to act on.</param>
        /// <param name="correlationId">The correlation Id string.</param>
        /// <returns>IDisposable defining the scope.</returns>
        public static IDisposable UseCorrelationScope(this ILogger logger, string correlationId)
        {
            return logger.BeginScope(new Dictionary<string, object> { { GeneralConstants.CorrelationIdKey, correlationId } });
        }

        /// <summary>
        /// Extension method to initialise the ScopedData instance from an incoming http Request.
        /// </summary>
        /// <param name="data">Reference to ScopedData instance.</param>
        /// <param name="req">The incoming http request.</param>
        /// <returns>boolean indicating whether any of the values have been set.</returns>
        public static bool InitialiseFromRequestHeaders(this ScopedData data, HttpRequest req)
        {
            bool updated = false;

            // If we have a correlation id in the header use it. This is preferred as we can still
            // log the creation of the BlobInfo object.
            if (req.Headers.ContainsKey(GeneralConstants.CorrelationIdHeaderName))
            {
                StringValues correlationId = req.Headers[GeneralConstants.CorrelationIdHeaderName];

                // We don't currently support a non-guid correlation id
                if (!Guid.TryParse(correlationId, out Guid corrId))
                    throw new NotSupportedException($"The {GeneralConstants.CorrelationIdHeaderName} header is not a valid Guid");

                data.AddCustomData(GeneralConstants.CorrelationIdKey, corrId.ToString());
                updated = true;
            }

            return updated;
        }
    }
}
