using EnrichmentPipeline.Functions.Domain.Interfaces;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using EnrichmentPipeline.Functions.Domain.Models;
using System;
using Microsoft.ApplicationInsights.Extensibility;
using EnrichmentPipeline.Functions.Domain.TelemetryInitializers;
using SixLabors.ImageSharp.Memory;
using SixLabors.ImageSharp;
using EnrichmentPipeline.Functions.Domain.Services;

[assembly: FunctionsStartup(typeof(EnrichmentPipeline.Functions.ImageResize.Startup))]
namespace EnrichmentPipeline.Functions.ImageResize
{
    public class Startup : FunctionsStartup
    {
        /// <summary>
        /// Configures the function with  injected services.
        /// </summary>
        /// <param name="builder">The function host builder.</param>
        public override void Configure(IFunctionsHostBuilder builder)
        {
            //  Registers the ILogger instance
            builder.Services.AddLogging(loggingBuilder =>
            {
                loggingBuilder.AddApplicationInsights();
                loggingBuilder.AddFilter("EnrichmentPipeline", LogLevel.Trace);
            });

            // Register services
            builder.Services.AddSingleton<ISystemInfoService, SystemInfoService>(isp => new SystemInfoService(typeof(Startup).Assembly));
            builder.Services.AddSingleton(isp => new StaticTelemetryProperties(isp.GetRequiredService<ISystemInfoService>())
            {
                ComponentName = typeof(Startup).Namespace,
                HostingEnvironment = "Functions",
                HostId = Environment.MachineName,
            });
            builder.Services.AddSingleton<ITelemetryInitializer, TelemetryInitializer>();

            builder.Services.AddApplicationInsightsTelemetry();

            // Configure ImageSharp array pooling
            Configuration.Default.MemoryAllocator = ArrayPoolMemoryAllocator.CreateWithModeratePooling();
        }
    }
}
