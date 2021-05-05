using System;
using Xunit;
using EnrichmentPipeline.Functions.WorkflowTrigger.Services;
using Microsoft.Extensions.Options;
using EnrichmentPipeline.Functions.WorkflowTrigger.Configurations;
using Azure.Messaging.ServiceBus;
using EnrichmentPipeline.Functions.Domain.Constants;

namespace EnrichmentPipeline.Functions.WorkflowTrigger.Tests
{
    public class ServiceBusClientServiceTests
    {
        private readonly IOptions<OutputServiceBusConfiguration> _outputServiceBusConfiguration;

        /// <summary>
        /// Constructor.
        /// </summary>
        public ServiceBusClientServiceTests()
        {
            _outputServiceBusConfiguration = Options.Create(new OutputServiceBusConfiguration()
            {
                ConnectionString = UnitTestExtensions.TestConnectionString,
                QueueName = UnitTestExtensions.TestQueuename,
            });
        }

        [Fact]
        public void CreateServiceBusClient_WhenNullConnectionString_ReturnsArgumentNullException()
        {
            // Arrange
            var sut = new ServiceBusClientService();

            // Act & Assert
            Assert.Throws<ArgumentNullException>(() => sut.CreateServiceBusClient(null));
        }

        [Fact]
        public void CreateServiceBusClient_WhenGivenGoodConnectionString_ReturnsNotNull()
        {
            // Arrange
            var sut = new ServiceBusClientService();

            // Act
            ServiceBusClient serviceBusClient = sut.CreateServiceBusClient(_outputServiceBusConfiguration.Value.ConnectionString);

            // Assert
            Assert.NotNull(serviceBusClient);
        }
    }
}
