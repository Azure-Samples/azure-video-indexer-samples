using System;

namespace EnrichmentPipeline.Functions.Domain.Exceptions
{
    /// <summary>
    /// Use when a SAS Uri has failed to be created.
    /// </summary>
    public class SASUriCreationFailedException : Exception
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="SASUriCreationFailedException"/> class.
        /// </summary>
        /// <param name="message">Error message.</param>
        public SASUriCreationFailedException(string message) : base(message)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="SASUriCreationFailedException"/> class.
        /// </summary>
        /// <param name="message">Error message.</param>
        /// <param name="innerException">Wrapped exception object.</param>
        public SASUriCreationFailedException(string message, Exception innerException) : base(message, innerException)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="SASUriCreationFailedException"/> class.
        /// </summary>
        public SASUriCreationFailedException()
        {
        }
    }
}
