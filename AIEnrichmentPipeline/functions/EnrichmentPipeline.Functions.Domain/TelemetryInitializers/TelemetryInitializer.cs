using System.Collections.Generic;
using System.Threading;
using EnrichmentPipeline.Functions.Domain.Models;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Newtonsoft.Json;

namespace EnrichmentPipeline.Functions.Domain.TelemetryInitializers
{
    /// <summary>
    /// TelemetryInitializer which is very specifically used to set a correlation Id that
    /// should marshal it's value to the context in which the telemetry data is associated
    /// with ITelemetry instances.
    /// </summary>
    public class TelemetryInitializer : ITelemetryInitializer
    {
        /// <summary>
        /// AdditionalContext to store telemetry data scoed to a run of a function, e.g. correlation id.
        /// </summary>
        public static readonly AsyncLocal<string> ScopedTelemetryProperties = new AsyncLocal<string>();

        private static JsonSerializerSettings _jsonSettings = new JsonSerializerSettings
        {
            Error = (s, e) => e.ErrorContext.Handled = true,
        };

        /// <summary>
        /// Initializes a new instance of the <see cref="TelemetryInitializer"/> class.
        /// </summary>
        /// <param name="telemetryProperties">Initial parameters.</param>
        public TelemetryInitializer(StaticTelemetryProperties telemetryProperties)
        {
            StaticTelemetryProperties = telemetryProperties;
        }

        private StaticTelemetryProperties StaticTelemetryProperties { get; }

        /// <summary>
        /// Sets ScopedTelemetryData.
        /// </summary>
        /// <param name="data">Custom name/value pairs to associate with telemetry items.</param>
        public static void SetScopedTelemetryProperties(Dictionary<string, string> data)
        {
            ScopedTelemetryProperties.Value = JsonConvert.SerializeObject(data);
        }

        /// <inheritdoc cref="ITelemetryInitializer"/>
        public void Initialize(ITelemetry telemetry)
        {
            if (telemetry is ISupportProperties propTelemetry)
            {
                // Add scoped data to the telemetry item
                if (ScopedTelemetryProperties.Value != null)
                {
                    Dictionary<string, string> customData =
                        JsonConvert.DeserializeObject<Dictionary<string, string>>(ScopedTelemetryProperties.Value, _jsonSettings);
                    if (customData != null)
                    {
                        foreach (KeyValuePair<string, string> element in customData)
                        {
                            propTelemetry.Properties[element.Key] = element.Value;
                        }
                    }
                }

                // Add static data to the telemetry item
                propTelemetry.Properties[nameof(StaticTelemetryProperties.SystemVersion)] = StaticTelemetryProperties.SystemVersion;
                propTelemetry.Properties[nameof(StaticTelemetryProperties.ComponentVersion)] = StaticTelemetryProperties.ComponentVersion;
                propTelemetry.Properties[nameof(StaticTelemetryProperties.ComponentName)] = StaticTelemetryProperties.ComponentName;
                propTelemetry.Properties[nameof(StaticTelemetryProperties.HostingEnvironment)] = StaticTelemetryProperties.HostingEnvironment;
                propTelemetry.Properties[nameof(StaticTelemetryProperties.HostId)] = StaticTelemetryProperties.HostId;
            }
        }
    }
}
