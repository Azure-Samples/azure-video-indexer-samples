using System;
using Moq;
using Xunit;
using System.Threading.Tasks;
using EnrichmentPipeline.Functions.WorkflowTrigger.Services;
using Microsoft.Extensions.Options;
using EnrichmentPipeline.Functions.WorkflowTrigger.Configurations;
using EnrichmentPipeline.Functions.Domain.Models;
using EnrichmentPipeline.Functions.WorkflowTrigger.Interfaces;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
using EnrichmentPipeline.Functions.Domain.Constants;

namespace EnrichmentPipeline.Functions.WorkflowTrigger.Tests
{
    public class ServiceBusServiceTests
    {
        private readonly BlobInfo _blobInfo;
        private readonly IOptions<OutputServiceBusConfiguration> _outputServiceBusConfiguration;
        private readonly Mock<IServiceBusClientService> _serviceBusClientService;
        private readonly Mock<ServiceBusClient> _serviceBusClient;
        private readonly Mock<ServiceBusSender> _serviceBusSender;

        /// <summary>
        /// Constructor.
        /// </summary>
        public ServiceBusServiceTests()
        {
            _blobInfo = new BlobInfo()
            {
                CanonicalUri = UnitTestExtensions.TestUri,
                CorrelationId = UnitTestExtensions.TestCorrelationId,
                FileName = UnitTestExtensions.TestFilename,
                FileCategory = UnitTestExtensions.TestFilename.Substring(UnitTestExtensions.TestFilename.LastIndexOf('.')),
                SasExpiry = DateTime.UtcNow.AddDays(1),
                SasUri = UnitTestExtensions.TestUri,
                SystemVersion = Guid.NewGuid().ToString()
            };

            _outputServiceBusConfiguration = Options.Create(new OutputServiceBusConfiguration()
            {
                ConnectionString = UnitTestExtensions.TestConnectionString,
                QueueName = UnitTestExtensions.TestQueuename,
            });

            _serviceBusClientService = new Mock<IServiceBusClientService>();

            _serviceBusClient = new Mock<ServiceBusClient>();

            _serviceBusSender = new Mock<ServiceBusSender>();
        }

        [Fact]
        public async Task SubmitBlobInfoToServiceBus_WhenCalledWithNullBlobInfo_ReturnsArgumentNullException()
        {
            // Arrange
            var loggerMock = new Mock<ILogger<ServiceBusService>>();

            var sut = new ServiceBusService(_outputServiceBusConfiguration, loggerMock.Object, _serviceBusClientService.Object);

            // Act & Assert
            await Assert.ThrowsAsync<ArgumentNullException>(() => sut.SubmitBlobInfoToServiceBus(null) );
        }

        [Fact]
        public async Task SubmitBlobInfoToServiceBus_ServiceBusException_ReturnsServiceBusException()
        {
            // Arrange
            var loggerMock = new Mock<ILogger<ServiceBusService>>();

            var sut = new ServiceBusService(_outputServiceBusConfiguration, loggerMock.Object, _serviceBusClientService.Object);
            _serviceBusClientService.Setup(x => x.CreateServiceBusClient(It.IsAny<string>())).Returns(_serviceBusClient.Object);
            _serviceBusClient.Setup(x => x.CreateSender(It.IsAny<string>())).Returns(_serviceBusSender.Object);
            _serviceBusSender.Setup(x => x.SendMessageAsync(It.IsAny<ServiceBusMessage>(), default)).ThrowsAsync(new ServiceBusException());

            // Act & Assert
            await Assert.ThrowsAsync<ServiceBusException>(() => sut.SubmitBlobInfoToServiceBus(_blobInfo));
        }

        [Fact]
        public async Task SubmitBlobInfoToServiceBus_GeneralException_ReturnsException()
        {
            // Arrange
            var loggerMock = new Mock<ILogger<ServiceBusService>>();

            var sut = new ServiceBusService(_outputServiceBusConfiguration, loggerMock.Object, _serviceBusClientService.Object);
            _serviceBusClientService.Setup(x => x.CreateServiceBusClient(It.IsAny<string>())).Returns(_serviceBusClient.Object);
            _serviceBusClient.Setup(x => x.CreateSender(It.IsAny<string>())).Returns(_serviceBusSender.Object);
            _serviceBusSender.Setup(x => x.SendMessageAsync(It.IsAny<ServiceBusMessage>(), default)).ThrowsAsync(new Exception());

            // Act & Assert
            await Assert.ThrowsAsync<Exception>(() => sut.SubmitBlobInfoToServiceBus(_blobInfo));
        }
    }
}
