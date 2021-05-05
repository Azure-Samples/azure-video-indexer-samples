using System;

namespace EnrichmentPipeline.Functions.Domain.Exceptions
{
    /// <summary>
    /// Use when an Exception class is needed to indicate that the Uri is already in
    /// use.
    /// </summary>
    public class ExistingUriException : Exception
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ExistingUriException"/> class.
        /// </summary>
        /// <param name="message">Custom Exception message.</param>
        public ExistingUriException(string message) : base(message)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ExistingUriException"/> class.
        /// </summary>
        /// <param name="message">Custom Exception message.</param>
        /// <param name="innerException">Originating Exception object.</param>
        public ExistingUriException(string message, Exception innerException) : base(message, innerException)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ExistingUriException"/> class.
        /// </summary>
        public ExistingUriException()
        {
        }
    }
}
