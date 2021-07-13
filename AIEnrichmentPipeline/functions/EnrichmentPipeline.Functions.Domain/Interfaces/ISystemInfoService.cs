namespace EnrichmentPipeline.Functions.Domain.Interfaces
{
    /// <summary>
    /// Provides System-level information.
    /// </summary>
    public interface ISystemInfoService
    {
        /// <summary>
        /// Provides a string identifying the build that was used to generate the containing component.
        /// </summary>
        string SystemVersion { get; }

        /// <summary>
        /// Provides a string git hash identifying the code version used to build this component.
        /// </summary>
        string ComponentVersion { get; }
    }
}
