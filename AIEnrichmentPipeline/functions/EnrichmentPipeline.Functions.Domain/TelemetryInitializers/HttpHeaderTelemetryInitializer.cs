using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Primitives;
using EnrichmentPipeline.Functions.Domain.Constants;

namespace EnrichmentPipeline.Functions.Domain.TelemetryInitializers
{
    /// <summary>
    /// Custom Telemetry Initializer to provide custom data in app insights telemetry
    /// See https://docs.microsoft.com/en-us/dotnet/api/microsoft.applicationinsights.extensibility.itelemetryinitializer?view=azure-dotnet .
    /// </summary>
    public class HttpHeaderTelemetryInitializer : ITelemetryInitializer
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="HttpHeaderTelemetryInitializer"/> class.
        /// </summary>
        /// <param name="httpContextAccessor">Provides access to the HttpContext.</param>
        public HttpHeaderTelemetryInitializer(IHttpContextAccessor httpContextAccessor)
        {
            HttpContextAccessor = httpContextAccessor;
        }

        /// <summary>
        /// Get the IHttpContextAccessor.
        /// </summary>
        public IHttpContextAccessor HttpContextAccessor { get; }

        /// <inheritdoc/>
        public void Initialize(ITelemetry telemetry)
        {
            // Called whenever ITelemetry-implementing objects are initialised so a good entry-point for
            // global changes to telemetry. In this case we are associating the correlation id from the
            // http header with all telemetry sent to App Insights.
            if (telemetry is ISupportProperties propTelemetry)
            {
                if (!propTelemetry.Properties.ContainsKey(GeneralConstants.CorrelationIdPropertyKey))
                {
                    bool res = HttpContextAccessor.HttpContext?.Request?.Headers?.TryGetValue(GeneralConstants.CorrelationIdHeaderName,
                        out StringValues headerValue) ?? false;
                    if (res && !string.IsNullOrEmpty(headerValue))
                    {
                        propTelemetry.Properties.Add(GeneralConstants.CorrelationIdPropertyKey, headerValue);
                    }
                }
            }
        }
    }
}
