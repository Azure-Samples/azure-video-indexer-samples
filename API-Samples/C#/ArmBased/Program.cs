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
            var videoId = await client.UrlUplopad(accountId, accountLocation, ExcludedAI, false);

            // Wait for the video index to finish
            await client.WaitForIndex(accountId, accountLocation, videoId);

            // Get video level access token for Azure Video Indexer 
            var videoAccessToken = await videoIndexerResourceProviderClient.GetAccessToken(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Video, videoId);

            // Search for the video
            await GetVideo(accountId, accountLocation, videoAccessToken, ApiUrl, client, videoId);

            // Get insights widget url
            await GetInsightsWidgetUrl(accountId, accountLocation, videoAccessToken, ApiUrl, client, videoId);

            // Get player widget url
            await GetPlayerWidgetUrl(accountId, accountLocation, videoAccessToken, ApiUrl, client, videoId);

            Console.WriteLine("\nPress Enter to exit...");
            var line = Console.ReadLine();
            if (line == "enter")
            {
                System.Environment.Exit(0);
            }
        }

        /// <summary>
        /// Uploads a video and starts the video index. Calls the uploadVideo API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video)
        /// </summary>
        /// <param name="accountId"> The account ID</param>
        /// <param name="accountLocation"> The account location </param>
        /// <param name="acountAccessToken"> The access token </param>
        /// <param name="apiUrl"> The video indexer api url </param>
        /// <param name="client"> The http client </param>
        /// <returns> Video Id of the video being indexed, otherwise throws excpetion</returns>



        

        /// <summary>
        /// Searches for the video in the account. Calls the searchVideo API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Search-Videos)
        /// </summary>
        /// <param name="accountId"> The account ID</param>
        /// <param name="accountLocation"> The account location </param>
        /// <param name="videoAccessToken"> The access token </param>
        /// <param name="apiUrl"> The video indexer api url </param>
        /// <param name="client"> The http client </param>
        /// <param name="videoId"> The video id </param>
        /// <returns> Prints the video metadata, otherwise throws excpetion</returns>
        private static async Task GetVideo(string accountId, string accountLocation, string videoAccessToken, string apiUrl, HttpClient client, string videoId)
        {
            Console.WriteLine($"\nSearching videos in account {AccountName} for video ID {videoId}.");
            var queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                        {"accessToken", videoAccessToken},
                        {"id", videoId},
                });

            try
            {
                var searchRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/Search?{queryParams}");

                VerifyStatus(searchRequestResult, System.Net.HttpStatusCode.OK);
                var searchResult = await searchRequestResult.Content.ReadAsStringAsync();
                Console.WriteLine($"Here are the search results: \n{searchResult}");
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }

        /// <summary>
        /// Calls the getVideoInsightsWidget API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Insights-Widget)
        /// </summary>
        /// <param name="accountId"> The account ID</param>
        /// <param name="accountLocation"> The account location </param>
        /// <param name="videoAccessToken"> The access token </param>
        /// <param name="apiUrl"> The video indexer api url </param>
        /// <param name="client"> The http client </param>
        /// <param name="videoId"> The video id </param>
        /// <returns> Prints the VideoInsightsWidget URL, otherwise throws exception</returns>
        private static async Task GetInsightsWidgetUrl(string accountId, string accountLocation, string videoAccessToken, string apiUrl, HttpClient client, string videoId)
        {
            Console.WriteLine($"\nGetting the insights widget URL for video {videoId}");
            var queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                    {"accessToken", videoAccessToken},
                    {"widgetType", "Keywords"},
                    {"allowEdit", "true"},
                });
            try
            {
                var insightsWidgetRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/{videoId}/InsightsWidget?{queryParams}");

                VerifyStatus(insightsWidgetRequestResult, System.Net.HttpStatusCode.MovedPermanently);
                var insightsWidgetLink = insightsWidgetRequestResult.Headers.Location;
                Console.WriteLine($"Got the insights widget URL: \n{insightsWidgetLink}");
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }

        /// <summary>
        /// Calls the getVideoPlayerWidget API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Player-Widget)
        /// </summary>
        /// <param name="accountId"> The account ID</param>
        /// <param name="accountLocation"> The account location </param>
        /// <param name="videoAccessToken"> The access token </param>
        /// <param name="apiUrl"> The video indexer api url </param>
        /// <param name="client"> The http client </param>
        /// <param name="videoId"> The video id </param>
        /// <returns> Prints the VideoPlayerWidget URL, otherwise throws exception</returns>
        private static async Task GetPlayerWidgetUrl(string accountId, string accountLocation, string videoAccessToken, string apiUrl, HttpClient client, string videoId)
        {
            Console.WriteLine($"\nGetting the player widget URL for video {videoId}");
            var queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                    {"accessToken", videoAccessToken},
                });

            try
            {
                var playerWidgetRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/{videoId}/PlayerWidget?{queryParams}");

                var playerWidgetLink = playerWidgetRequestResult.Headers.Location;
                VerifyStatus(playerWidgetRequestResult, System.Net.HttpStatusCode.MovedPermanently);
                Console.WriteLine($"Got the player widget URL: \n{playerWidgetLink}");
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }

        

        

        public class VideoIndexerResourceProviderClient
        {
            private readonly string armAccessToken;

            async public static Task<VideoIndexerResourceProviderClient> BuildVideoIndexerResourceProviderClient()
            {
                var tokenRequestContext = new TokenRequestContext(new[] { $"{AzureResourceManager}/.default" });
                var tokenRequestResult = await new DefaultAzureCredential().GetTokenAsync(tokenRequestContext);
                return new VideoIndexerResourceProviderClient(tokenRequestResult.Token);
            }
            public VideoIndexerResourceProviderClient(string armAaccessToken)
            {
                this.armAccessToken = armAaccessToken;
            }

            

           
        }

        
       

        public static void VerifyStatus(HttpResponseMessage response, System.Net.HttpStatusCode excpectedStatusCode)
        {
            if (response.StatusCode != excpectedStatusCode)
            {
                throw new Exception(response.ToString());
            }
        }
    }
}
