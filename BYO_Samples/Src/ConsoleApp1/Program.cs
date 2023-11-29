using CarDetectorApp;
using Microsoft.Extensions.Logging;

namespace ConsoleApp1
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            var loggerFactory = LoggerFactory.Create(builder =>
            {
                // Add the ConsoleLogger with a specified log level
                builder.AddConsole();
            });

            // Create an ILogger instance
            var logger = loggerFactory.CreateLogger<Program>();
            IndexingEventHandler viClient = new IndexingEventHandler(logger);

            await viClient.ProcessIndexingRecored(null);
        }
    }
}
