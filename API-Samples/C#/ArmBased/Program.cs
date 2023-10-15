using Azure.Core;
using Azure.Identity;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using System.Web;
using VideoIndexerClient;

namespace VideoIndexingARMAccounts
{
    public class Program
    {
        private const string ApiVersion = "2022-08-01";
        private const string SubscriptionId = "<Your_Subscription_ID>";
        private const string ResourceGroup = "<Your_Resource_Group>";
        private const string AccountName = "<Your_Account_Name>";
        
        //Choose public Access Video URL or File Path
        private const string VideoUrl = "<Your Video Url Here>";
        //OR 
        private const string LocalVideoPath = "<Your Video File Path Here>";
        
        // Enter a list seperated by a comma of the AIs you would like to exclude in the format "<Faces,Labels,Emotions,ObservedPeople>". Leave empty if you do not want to exclude any AIs. For more see here https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video:~:text=AI%20to%20exclude%20when%20indexing%2C%20for%20example%20for%20sensitive%20scenarios.%20Options%20are%3A%20Face/Observed%20peopleEmotions/Labels%7D.
        private const string ExcludedAI = ""; 

        public static async Task Main(string[] args)
        {
            // Create viode Indexer Client
            var client = new VideoIndexerClient.VideoIndexerClient();
            //Get Access Tokens
            await client.Authenticate();

            //1. Sample 1 : Get account details
            var account = await client.GetAccount(AccountName);
            var accountLocation = account.Location;
            var accountId = account.Properties.Id;


            //2. Sample 2 :  Upload a video , do not wait for the index operation to complete
            var videoId = await client.UrlUplopad(VideoUrl, "my-video-1", ExcludedAI, false);

            //2A. Sample 2A : Upload From Local File 
            //var fileVideoId = await client.FileUpload("my-video-2", LocalVideoPath, null, null);

            // Wait for the video index to finish
            await client.WaitForIndex(videoId);

            // Get video level access token for Azure Video Indexer 
            //var videoAccessToken = await videoIndexerResourceProviderClient.GetAccessToken(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Video, videoId);

            // Search for the video
            await client.GetVideo(videoId);

            // Get insights widget url
            await client.GetInsightsWidgetUrl(videoId);

            // Get player widget url
            await client.GetPlayerWidgetUrl(videoId);

            Console.WriteLine("\nPress Enter to exit...");
            var line = Console.ReadLine();
            if (line == "enter")
            {
                System.Environment.Exit(0);
            }
        }

        



        

       

        

        
        
        
       

        
    }
}
