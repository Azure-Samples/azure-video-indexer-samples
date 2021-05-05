using System;
using Azure.Storage;
using Azure.Storage.Files.DataLake;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using EnrichmentPipeline.Functions.Domain.Configuration;
using EnrichmentPipeline.Functions.Domain.Interfaces;
using EnrichmentPipeline.Functions.Domain.Models;
using EnrichmentPipeline.Functions.Domain.Services;
using EnrichmentPipeline.Functions.Domain.TelemetryInitializers;
using EnrichmentPipeline.Functions.WorkflowTrigger.Configurations;
using EnrichmentPipeline.Functions.WorkflowTrigger.Interfaces;
using EnrichmentPipeline.Functions.WorkflowTrigger.Services;

[assembly: FunctionsStartup(typeof(EnrichmentPipeline.Functions.WorkflowTrigger.Startup))]
namespace EnrichmentPipeline.Functions.WorkflowTrigger
{
    /// <summary>
    /// Startup for WorkflowTrigger.
    /// </summary>
    public class Startup : FunctionsStartup
    {
        /// <summary>
        /// Configure for WorkflowTrigger.
        /// </summary>
        /// <param name="builder">IFunctionsHostBuilder.</param>
        public override void Configure(IFunctionsHostBuilder builder)
        {
            //  Registers the ILogger instance
            builder.Services.AddLogging(loggingBuilder =>
            {
                loggingBuilder.AddApplicationInsights();

                loggingBuilder.AddFilter("EnrichmentPipeline", LogLevel.Trace);
            });

            builder
                .Services
                .AddOptions<DataLakeConfiguration>()
                .Configure<IConfiguration>((settings, configuration) =>
                {
                    configuration.GetSection(nameof(DataLakeConfiguration)).Bind(settings);
                });

            builder
               .Services
               .AddOptions<OutputServiceBusConfiguration>()
               .Configure<IConfiguration>((settings, configuration) =>
               {
                   configuration.GetSection(nameof(OutputServiceBusConfiguration)).Bind(settings);
               });

            builder.Services.AddSingleton<ISystemInfoService, SystemInfoService>(isp => new SystemInfoService(typeof(Startup).Assembly));
            builder.Services.AddSingleton(isp => new StaticTelemetryProperties(isp.GetRequiredService<ISystemInfoService>())
            {
                ComponentName = typeof(Startup).Namespace,
                HostingEnvironment = "Functions",
                HostId = Environment.MachineName,
            });
            builder.Services.AddSingleton<ITelemetryInitializer, TelemetryInitializer>();
            builder.Services.AddSingleton<IServiceBusClientService, ServiceBusClientService>();
            builder.Services.AddSingleton<IServiceBusService, ServiceBusService>();
            builder.Services.AddSingleton<IFileStorageService, FileStorageService>();
            builder.Services.AddSingleton<IBlobInfoFactoryService, BlobInfoFactoryService>();
            builder.Services.AddApplicationInsightsTelemetry();
            builder.Services.AddSingleton(x =>
            {
                DataLakeConfiguration dataLakeConfigValue = x.GetRequiredService<IOptions<DataLakeConfiguration>>().Value;
                StorageSharedKeyCredential sharedKeyCredential = new StorageSharedKeyCredential(dataLakeConfigValue.Name, dataLakeConfigValue.Key);
                return new DataLakeServiceClient(new Uri(dataLakeConfigValue.Uri), sharedKeyCredential);
            });
        }
    }
}
