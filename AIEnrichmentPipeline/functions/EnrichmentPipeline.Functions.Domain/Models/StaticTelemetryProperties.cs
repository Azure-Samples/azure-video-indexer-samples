using EnrichmentPipeline.Functions.Domain.Interfaces;

namespace EnrichmentPipeline.Functions.Domain.Models
{
    /// <summary>
    /// Class to store properties for telemetry items.
    /// </summary>
    public class StaticTelemetryProperties
    {
        private readonly ISystemInfoService _systemInfo;

        /// <summary>
        /// Initializes a new instance of the <see cref="StaticTelemetryProperties"/> class.
        /// </summary>
        /// <param name="systemInfo">Interfaces provides system-level information.</param>
        public StaticTelemetryProperties(ISystemInfoService systemInfo)
        {
            _systemInfo = systemInfo;
        }

        /// <summary>
        /// System Version label.
        /// </summary>
        public string SystemVersion
        {
            get { return _systemInfo.SystemVersion; }
        }

        /// <summary>
        /// Git Hash of the Assembly.
        /// </summary>
        public string ComponentVersion
        {
            get { return _systemInfo.ComponentVersion; }
        }

        /// <summary>
        /// Name of the component.
        /// </summary>
        public string ComponentName { get; set; }

        /// <summary>
        /// Type of hosting environment.
        /// </summary>
        public string HostingEnvironment { get; set; }

        /// <summary>
        /// Name of the host.
        /// </summary>
        public string HostId { get; set; }

        /// <summary>
        /// CorrelationId property value.
        /// </summary>
        public string CorrelationId { get; set; }
    }
}
