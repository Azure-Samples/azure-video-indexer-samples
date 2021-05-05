namespace EnrichmentPipeline.Functions.WorkflowTrigger.Configurations
{
    /// <summary>
    /// Configuration settings for the output service bus.
    /// </summary>
    public class OutputServiceBusConfiguration
    {
        /// <summary>
        /// ConnectionString for the output service bus.
        /// </summary>
        public string ConnectionString { get; set; }

        /// <summary>
        /// QueueName for the output service bus.
        /// </summary>
        public string QueueName { get; set; }
    }
}
