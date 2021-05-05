namespace EnrichmentPipeline.Functions.Domain.Configuration
{
    /// <summary>
    /// Class containing all storage account properties.
    /// </summary>
    public class DataLakeConfiguration
    {
        /// <summary>
        /// Primary Storage Account Name.
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Primary Storage Account Key.
        /// </summary>
        public string Key { get; set; }

        /// <summary>
        /// Datalake Endpoint Uri.
        /// </summary>
        public string Uri { get; set; }

        /// <summary>
        /// Datalake connection string.
        /// </summary>
        public string ConnectionString { get; set; }

        /// <summary>
        /// Datalake Input Container Name.
        /// </summary>
        public string InputContainerName { get; set; }

        /// <summary>
        /// Datalake EnrichmentData Container Name.
        /// </summary>
        public string EnrichmentDataContainerName { get; set; }
    }
}
