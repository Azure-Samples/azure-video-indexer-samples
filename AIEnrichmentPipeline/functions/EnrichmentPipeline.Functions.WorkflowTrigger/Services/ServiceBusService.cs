using System;
using System.Collections.Generic;
using System.Net.Mime;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using EnrichmentPipeline.Functions.Domain.Configuration;
using EnrichmentPipeline.Functions.Domain.Models;
using EnrichmentPipeline.Functions.WorkflowTrigger.Configurations;
using EnrichmentPipeline.Functions.WorkflowTrigger.Helpers;
using EnrichmentPipeline.Functions.WorkflowTrigger.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;

namespace EnrichmentPipeline.Functions.WorkflowTrigger.Services
{
    /// <inheritdoc/>
    public class ServiceBusService : IServiceBusService
    {
        private readonly OutputServiceBusConfiguration _outputServiceBusConfiguration;
        private readonly ILogger _logger;
        private readonly IServiceBusClientService _serviceBusClientService;

        /// <summary>
        /// Initializes a new instance of the <see cref="ServiceBusService"/> class.
        /// </summary>
        /// <param name="outputServiceBusConfiguration">Injected OutputServiceBusConfiguration.</param>
        /// <param name="logger">Injected ILogger.</param>
        /// <param name="serviceBusClientService">Injected ServiceBusClientService.</param>
        public ServiceBusService(IOptions<OutputServiceBusConfiguration> outputServiceBusConfiguration, ILogger<ServiceBusService> logger, IServiceBusClientService serviceBusClientService)
        {
            _outputServiceBusConfiguration = outputServiceBusConfiguration.Value;
            _logger = logger;
            _serviceBusClientService = serviceBusClientService;
        }

        /// <inheritdoc/>
        public async Task SubmitBlobInfoToServiceBus(BlobInfo blobInfo)
        {
            if (blobInfo == null)
            {
                throw new ArgumentNullException(nameof(blobInfo));
            }

            // Create and send service bus message
            try
            {
                await using ServiceBusClient client = _serviceBusClientService.CreateServiceBusClient(_outputServiceBusConfiguration.ConnectionString);
                ServiceBusSender sender = client.CreateSender(_outputServiceBusConfiguration.QueueName);
                string json = JsonConvert.SerializeObject(blobInfo, DefaultJsonSerializerSettings.Settings);
                ServiceBusMessage message = new ServiceBusMessage(json)
                {
                    ContentType = MediaTypeNames.Application.Json,
                };
                await sender.SendMessageAsync(message);
            }
            catch (ServiceBusException ex)
            {
                _logger.LogError(ex, "An error occured when submitting blob info to Service Bus");
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception when submitting blob info to Service Bus");
                throw;
            }
        }
    }
}
