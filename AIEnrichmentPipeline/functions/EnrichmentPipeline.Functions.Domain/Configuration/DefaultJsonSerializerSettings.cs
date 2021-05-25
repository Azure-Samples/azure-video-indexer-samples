using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace EnrichmentPipeline.Functions.Domain.Configuration
{
    /// <summary>
    /// Static set of default settings for JSON serialization.
    /// </summary>
    public static class DefaultJsonSerializerSettings
    {
        /// <summary>
        /// Gets default serializer settings.
        /// </summary>
        public static JsonSerializerSettings Settings { get; } = new JsonSerializerSettings()
        {
            ContractResolver = new DefaultContractResolver
            {
                NamingStrategy = new CamelCaseNamingStrategy
                {
                    OverrideSpecifiedNames = false,
                },
            },
            Formatting = Formatting.Indented,
        };
    }
}
