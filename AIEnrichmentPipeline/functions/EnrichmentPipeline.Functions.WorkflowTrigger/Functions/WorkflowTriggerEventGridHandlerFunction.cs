// Default URL for triggering event grid function in the local environment.
// http://localhost:7071/runtime/webhooks/EventGrid?functionName={functionname}
using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using EnrichmentPipeline.Functions.Domain;
using EnrichmentPipeline.Functions.Domain.Constants;
using EnrichmentPipeline.Functions.Domain.Interfaces;
using EnrichmentPipeline.Functions.Domain.Models;
using EnrichmentPipeline.Functions.WorkflowTrigger.Interfaces;
using Microsoft.Azure.EventGrid.Models;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.EventGrid;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace EnrichmentPipeline.Functions.WorkflowTrigger.Functions
{
    /// <summary>
    /// Event grid handler function.
    /// </summary>
    public class WorkflowTriggerEventGridHandlerFunction
    {
        private const string _functionName = "WorkflowTriggerEventGridHandlerFunction";
        private readonly IBlobInfoFactoryService _blobInfoFactoryService;
        private readonly IServiceBusService _serviceBusService;

        /// <summary>
        /// Initializes a new instance of the <see cref="WorkflowTriggerEventGridHandlerFunction"/> class.
        /// </summary>
        /// <param name="blobInfoFactoryService">Injected IBlobInfoFactoryService.</param>
        /// <param name="serviceBusService">Injected IServiceBusService.</param>
        public WorkflowTriggerEventGridHandlerFunction(
            IBlobInfoFactoryService blobInfoFactoryService,
            IServiceBusService serviceBusService)
        {
            _blobInfoFactoryService = blobInfoFactoryService;
            _serviceBusService = serviceBusService;
        }

        /// <summary>
        /// Run method (main entry point) for event grid handler trigger.
        /// </summary>
        /// <param name="eventGridEvent">Event grid event.</param>
        /// <param name="log">Logger.</param>
        /// <returns>A <see cref="Task"/> representing the asynchronous operation.</returns>
        [FunctionName(_functionName)]
        [ExcludeFromCodeCoverage] //This function just calls other services which are tested so there is no logic here that can be tested.
        public async Task RunAsync([EventGridTrigger]EventGridEvent eventGridEvent, ILogger log)
        {
            try
            {
                // Get data from event grid event
                dynamic eventGridEventData = JsonConvert.DeserializeObject(eventGridEvent.Data.ToString());
                Uri uri = new Uri(eventGridEventData.url.ToString());

                // Generate correlation id and set Telemetry
                Guid correlation = _blobInfoFactoryService.CreateCorrelationId();
                ScopedData scopedData = new ScopedData();
                scopedData.AddCustomData(GeneralConstants.CorrelationIdKey, correlation.ToString()).Apply();
                log.LogInformation("Started: {functionName} {uri}, {name}", _functionName, uri, uri.Segments.Last());

                // Exclude empty files and folders
                if (!string.IsNullOrEmpty(uri.AbsoluteUri))
                {
                    // Generate BlobInfo
                    BlobInfo blobInfo = _blobInfoFactoryService.CreateBlobInfo(uri, uri.Segments.Last(), correlation);
                    log.LogInformation("{functionName}: created BlobInfo", _functionName);

                    // Send service bus message
                    await _serviceBusService.SubmitBlobInfoToServiceBus(blobInfo);
                    log.LogInformation("{functionName}: submitted BlobInfo to Service Bus", _functionName);
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, "{functionName}: Failed to submit BlobInfo to Service Bus for {eventData}", _functionName, eventGridEvent.Data.ToString());
                throw;
            }
            finally
            {
                log.LogInformation("{functionName}: Completed {eventData}", _functionName, eventGridEvent.Data.ToString());
            }
        }
    }
}
