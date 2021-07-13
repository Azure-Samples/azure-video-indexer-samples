using System;

namespace EnrichmentPipeline.Functions.Domain.Exceptions
{
    /// <summary>
    /// Use when an Exception class is needed to indicate misconfigured environment.
    /// e.g. Required environment variable not found.
    /// </summary>
    public class EnvironmentNotConfiguredException : Exception
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="EnvironmentNotConfiguredException"/> class.
        /// Standard Exception constructor with custom message.
        /// </summary>
        /// <param name="message">Custom Exception message.</param>
        public EnvironmentNotConfiguredException(string message) : base(message)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="EnvironmentNotConfiguredException"/> class.
        /// </summary>
        /// <param name="message">Custom Exception message.</param>
        /// <param name="innerException">Originating Exception object.</param>
        public EnvironmentNotConfiguredException(string message, Exception innerException) : base(message, innerException)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="EnvironmentNotConfiguredException"/> class.
        /// </summary>
        public EnvironmentNotConfiguredException()
        {
        }
    }
}
