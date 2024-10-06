using System;
using System.Collections.Concurrent;
using System.IO;
using System.Threading.Tasks;
// ReSharper disable All

namespace VideoIndexingARMAccounts
{
    public static class Consts
    {
        public const string ApiVersion = "2022-08-01";
        public const string AzureResourceManager = "https://management.azure.com";
        public static readonly string SubscriptionId = Environment.GetEnvironmentVariable("SUBSCIPTION_ID");
        public static readonly string ResourceGroup = Environment.GetEnvironmentVariable("VI_RESOURCE_GROUP");
        public static readonly string ViAccountName = Environment.GetEnvironmentVariable("VI_ACCOUNT_NAME");
        public static readonly string ApiEndpoint = Environment.GetEnvironmentVariable("API_ENDPOINT") ?? "https://api.videoindexer.ai";

        public static bool Valid() => !string.IsNullOrWhiteSpace(SubscriptionId) &&
                               !string.IsNullOrWhiteSpace(ResourceGroup) &&
                               !string.IsNullOrWhiteSpace(ViAccountName);
    }

    public class Program
    {
        //Choose public Access Video URL or File Path
        private const string VideoUrl = "<Enter Your Video URL Here>";
        //OR 
        private const string LocalVideoPath = "<Your Video File Path Here>";
        
        // Enter a list seperated by a comma of the AIs you would like to exclude in the format "<Faces,Labels,Emotions,ObservedPeople>". Leave empty if you do not want to exclude any AIs. For more see here https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video:~:text=AI%20to%20exclude%20when%20indexing%2C%20for%20example%20for%20sensitive%20scenarios.%20Options%20are%3A%20Face/Observed%20peopleEmotions/Labels%7D.
        private const string ExcludedAI = ""; 

        public static async Task Main(string[] args)
        {
            Console.WriteLine("Video Indexer API Samples ");
            Console.WriteLine("=========================== ");

            if (!Consts.Valid())
            {
                throw new Exception("Please Fill In SubscriptionId, Account Name and Resource Group on the Constant Class !");
            }
            
            // Create Video Indexer Client
            var client = new VideoIndexerClient.VideoIndexerClient();
            //Get Access Tokens
            await client.AuthenticateAsync();

            //1. Sample 1 : Get account details, not required in most cases
            Console.WriteLine("Sample1- Get Account Basic Details");
            await client.GetAccountAsync(Consts.ViAccountName);

            //2. Sample 2 :  Upload a video , do not wait for the index operation to complete. 
            Console.WriteLine("Sample2- Index a Video from URL");
            var videoId = await client.UploadUrlAsync(VideoUrl, "my-video-name", ExcludedAI, false);
            
            //2A. Sample 2A : Upload From Local File 
            if (File.Exists(LocalVideoPath))
            {
                Console.WriteLine("Sample 2A - Index a video From File");
                var fileVideoId = await client.FileUploadAsync("my-other-video-name", LocalVideoPath);
            }

            // Sample 3 : Wait for the video index to finish ( Polling method)
            Console.WriteLine("Sample 3 - Polling on Video Completion Event");
            await client.WaitForIndexAsync(videoId);

            // Sample 4: Search for the video and get insights
            Console.WriteLine("Sample 4 - Search for Video And get insights");
            await client.GetVideoAsync(videoId);

            // Sample 5: Widgets API's
            Console.WriteLine("Sample 5- Widgets API");
            await client.GetInsightsWidgetUrlAsync(videoId);
            await client.GetPlayerWidgetUrlAsync(videoId);
            


            Console.WriteLine("\nPress Enter to exit...");
            var line = Console.ReadLine();
            if (line == "enter")
            {
                System.Environment.Exit(0);
            }
        }

    }
}
