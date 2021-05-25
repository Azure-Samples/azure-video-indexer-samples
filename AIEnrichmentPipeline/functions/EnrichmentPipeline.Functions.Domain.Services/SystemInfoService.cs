using System.Linq;
using System.Reflection;
using EnrichmentPipeline.Functions.Domain.Interfaces;

namespace EnrichmentPipeline.Functions.Domain.Services
{
    /// <summary>
    /// Provides System-level information.
    /// </summary>
    public class SystemInfoService : ISystemInfoService
    {
        // Delimiter to separate data in the version string.
        private const string Separator = "+";

        // Default to this version string when we have built the assemblies without specifying a version, i.e. in local development.
        private const string DefaultVersion = "SysVersion" + Separator + "LOCALBUILD";

        /// <summary>
        /// Initializes a new instance of the <see cref="SystemInfoService"/> class.
        /// </summary>
        public SystemInfoService(Assembly assembly)
        {
            ReadVersions(assembly);
        }

        /// <inheritdoc/>
        public string SystemVersion { get; private set; }

        /// <inheritdoc/>
        public string ComponentVersion { get; private set; }

        private void ReadVersions(Assembly appAssembly, string version = DefaultVersion)
        {
            AssemblyInformationalVersionAttribute infoVerAttr = (AssemblyInformationalVersionAttribute)appAssembly
                .GetCustomAttributes(typeof(AssemblyInformationalVersionAttribute)).FirstOrDefault();

            // Ensure that we have retrieved an InformationalVersion in the format that we expect. This will include the version as well at the beginning.
            if (infoVerAttr != null && !string.IsNullOrEmpty(infoVerAttr.InformationalVersion) && infoVerAttr.InformationalVersion.Contains(Separator))
            {
                // System Version / Hash are separated by '+' symbols,
                // e.g. 1.0.11111.89+a34a913742f8845d3da5309b7b17242222d41a21
                version = infoVerAttr.InformationalVersion;
            }

            string[] subStrings = version.Split(Separator[0]);

            SystemVersion = subStrings[0];
            if (subStrings.Length == 2)
            {
                ComponentVersion = subStrings[1];
            }
        }
    }
}
