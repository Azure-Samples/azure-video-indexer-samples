using System;
using System.IO;
using System.Text;

namespace EnrichmentPipeline.Functions.Domain.Constants
{
    /// <summary>
    /// Constant values used used for unit tests.
    /// </summary>
    public static class UnitTestExtensions
    {
        /// <summary>
        /// Whenever a unit test needs an arbitrary hash value string.
        /// </summary>
        public const string TestHashValue = "03-4A-F7-1F-EB-3B-B0-8E-FC-02-BF-31-30-C7-F0-72-4C-BD-25-C1-1A-0D-A3-CC-37-3F-48-69-8B-97-8A-BA";

        /// <summary>
        /// Whenever a unit test needs an arbitrary uri string.
        /// </summary>
        public static readonly Uri TestUri = new Uri("https://www.bing.com/wibble");

        /// <summary>
        /// Whenever a unit test needs an arbitrary filename string.
        /// </summary>
        public static readonly string TestFilename = "bibble/testFile.png";

        /// <summary>
        /// Whenever a unit test needs a correlation id string.
        /// </summary>
        public static readonly Guid TestCorrelationId = Guid.Parse("0EBAF131-091E-4DD8-AD93-081578CF4FF8");

        /// <summary>
        /// Whenever a unit test needs an arbitrary connection string.
        /// </summary>
        public static readonly string TestConnectionString = "Endpoint=sb://someservicebus.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=123456789123456789123456789";

        /// <summary>
        /// Whenever a unit test needs an arbitrary service bus queue name.
        /// </summary>
        public static readonly string TestQueuename = "myqueue";

        /// <summary>
        /// Whenever a unit test needs an arbitrary Stream.
        /// </summary>
        /// <returns>The test stream.</returns>
        public static Stream TestStream()
        {
            return new MemoryStream(Encoding.UTF8.GetBytes("aaaaaaaaaaabbbbbbbbbbbbbbbbcccccccccccccc"));
        }
    }
}
