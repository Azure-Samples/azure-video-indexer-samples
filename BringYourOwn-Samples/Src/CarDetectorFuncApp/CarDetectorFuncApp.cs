using System.Net;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace CarDetectorApp
{
    public class CarDetectorFuncApp
    {
        private const string EventHubsName = "vilogs";
        private const string CSConfigName = "EHCONNECTION";
        
        public CarDetectorFuncApp()
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12 | SecurityProtocolType.Tls13;
        }

        [FunctionName("CarDetectorFunc")]
        public static async Task Run([EventHubTrigger(eventHubName: EventHubsName , Connection = CSConfigName)] EventData[] events, ILogger log)
        {
            log.LogInformation("CarDetectorFunc invoked from EventHubs Listener Trigger {0}", EventHubsName);
            AppLogger.Logger = log;
            await (new IndexingEventHandler()).OnEventReceived(events);
            log.LogInformation("Finished Processing on event Hub {0}", EventHubsName);
        }
    }
}
