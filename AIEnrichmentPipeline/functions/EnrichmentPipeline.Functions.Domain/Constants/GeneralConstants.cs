namespace EnrichmentPipeline.Functions.Domain.Constants
{
    /// <summary>
    /// Class to use to define shared constants.
    /// </summary>
    public static class GeneralConstants
    {
        /// <summary>
        /// Error message when BlobInfo creation fails.
        /// </summary>
        public const string FailedToCreateBlobInfoMessage = "Unable to create BlobInfo object";

        /// <summary>
        /// Header name used for correlation id.
        /// </summary>
        public const string CorrelationIdHeaderName = "x-ms-client-tracking-id";

        /// <summary>
        /// Key name used for correlation id.
        /// </summary>
        public const string CorrelationIdKey = "CorrelationId";

        /// <summary>
        /// Key string used to associate the Correlation ID as a custom property.
        /// </summary>
        public const string CorrelationIdPropertyKey = "correlationId";

        /// <summary>
        /// Function succeeded message template.
        /// </summary>
        public const string FunctionSuccessMessage = "Success: {FunctionName} {uri} submitted to logic app.";

        /// <summary>
        /// Function failed message template.
        /// </summary>
        public const string FunctionErrorMessage = "Error: {FunctionName} {uri} processsing was NOT successful.";

        /// <summary>
        /// Function started message template.
        /// </summary>
        public const string FunctionStartedMessage = "Started: {FunctionName} Triggered by {uri}.";

        /// <summary>
        /// Function completed message template.
        /// </summary>
        public const string FunctionCompletedMessage = "Completed: {FunctionName} Triggered by {uri}.";
    }
}
