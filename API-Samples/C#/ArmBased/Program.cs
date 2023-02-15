using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using System.Web;
using Azure.Core;
using Azure.Identity;


namespace VideoIndexerArm
{
    public class Program
    {
        private const string ApiVersion = "2022-08-01";
        private const string AzureResourceManager = "https://management.azure.com";
        private const string SubscriptionId = "<Your Subscription Id Here>";
        private const string ResourceGroup = "<Your Resource Gropup Name Here>";
        private const string AccountName = "<Your Video Indexer Account Name Here>";
        private const string VideoUrl = "<Your Video Url Here>";
        private const string ApiUrl = "https://api.videoindexer.ai";

        public static async Task Main(string[] args)
        {
            // Build Azure Video Indexer resource provider client that has access token throuhg ARM
            var videoIndexerResourceProviderClient = await VideoIndexerResourceProviderClient.BuildVideoIndexerResourceProviderClient();

            // Get account details
            var account = await videoIndexerResourceProviderClient.GetAccount();
            var accountLocation = account.Location;
            var accountId = account.Properties.Id;

            // Get account level access token for Azure Video Indexer 
            var accountAccessToken = await videoIndexerResourceProviderClient.GetAccessToken(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Account);

            System.Net.ServicePointManager.SecurityProtocol |= System.Net.SecurityProtocolType.Tls12;

            // Create the http client
            var handler = new HttpClientHandler
            {
                AllowAutoRedirect = false
            };
            var client = new HttpClient(handler);

            // Upload a video
            var videoId = await UploadVideo(accountId, accountLocation, accountAccessToken, ApiUrl, client);

            // Wait for the video index to finish
            await WaitForIndex(accountId, accountLocation, accountAccessToken, ApiUrl, client, videoId);

            // Get video level access token for Azure Video Indexer 
            var videoAccessToken = await videoIndexerResourceProviderClient.GetAccessToken(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Video, videoId);

            // Search for the video
            await GetVideo(accountId, accountLocation, videoAccessToken, ApiUrl, client, videoId);

            // Get insights widget url
            await GetInsightsWidgetUrl(accountId, accountLocation, videoAccessToken, ApiUrl, client, videoId);

            // Get player widget url
            await GetPlayerWidgetUrl(accountId, accountLocation, videoAccessToken, ApiUrl, client, videoId);

            Console.WriteLine("\nPress Enter to exit...");
            String line = Console.ReadLine();
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
        private static async Task<string> UploadVideo(string accountId, string accountLocation, string acountAccessToken, string apiUrl, HttpClient client)
        {
            Console.WriteLine($"Video for account {accountId} is starting to upload.");
            var content = new MultipartFormDataContent();

            try
            {
                // Get the video from URL
                var queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                    {"accessToken", acountAccessToken},
                    {"name", "video sample"},
                    {"description", "video_description"},
                    {"privacy", "private"},     
                    {"partition", "partition"},
                    {"videoUrl", VideoUrl},
                });

                // As an alternative to specifying video URL, you can upload a file.
                // Remove the videoUrl parameter from the query params below and add the following lines:
                // FileStream video =File.OpenRead(Globals.VIDEOFILE_PATH);
                // byte[] buffer =new byte[video.Length];
                // video.Read(buffer, 0, buffer.Length);
                // content.Add(new ByteArrayContent(buffer));

                var uploadRequestResult = await client.PostAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos?{queryParams}", content);
                VerifyStatus(uploadRequestResult, System.Net.HttpStatusCode.OK);
                var uploadResult = await uploadRequestResult.Content.ReadAsStringAsync();

                // Get the video ID from the upload result
                var videoId = JsonSerializer.Deserialize<Video>(uploadResult).Id;
                Console.WriteLine($"\nVideo ID {videoId} was uploaded successfully");
                return videoId;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
                throw;
            }
        }

        /// <summary>
        /// Calls getVideoIndex API in 10 second intervals until the indexing state is 'processed'(https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Index)
        /// </summary>
        /// <param name="accountId"> The account ID</param>
        /// <param name="accountLocation"> The account location </param>
        /// <param name="acountAccessToken"> The access token </param>
        /// <param name="apiUrl"> The video indexer api url </param>
        /// <param name="client"> The http client </param>
        /// <param name="videoId"> The video id </param>
        /// <returns> Prints video index when the index is complete, otherwise throws exception </returns>
        private static async Task WaitForIndex(string accountId, string accountLocation, string acountAccessToken, string apiUrl, HttpClient client, string videoId)
        {
            Console.WriteLine($"\nWaiting for video {videoId} to finish indexing.");
            string queryParams;
            while (true)
            {
                queryParams = CreateQueryString(
                    new Dictionary<string, string>()
                    {
                            {"accessToken", acountAccessToken},
                            {"language", "English"},
                    });

                var videoGetIndexRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/{videoId}/Index?{queryParams}");

                VerifyStatus(videoGetIndexRequestResult, System.Net.HttpStatusCode.OK);
                var videoGetIndexResult = await videoGetIndexRequestResult.Content.ReadAsStringAsync();
                string processingState = JsonSerializer.Deserialize<Video>(videoGetIndexResult).State;

                // If job is finished
                if (processingState == ProcessingState.Processed.ToString())
                {
                    Console.WriteLine($"The video index has completed. Here is the full JSON of the index for video ID {videoId}: \n{videoGetIndexResult}");
                    return;
                }
                else if (processingState == ProcessingState.Failed.ToString())
                {
                    Console.WriteLine($"\nThe video index failed for video ID {videoId}.");
                    throw new Exception(videoGetIndexResult);
                }

                // Job hasn't finished
                Console.WriteLine($"\nThe video index state is {processingState}");
                await Task.Delay(10000);
            }
        }

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

        static string CreateQueryString(IDictionary<string, string> parameters)
        {
            var queryParameters = HttpUtility.ParseQueryString(string.Empty);
            foreach (var parameter in parameters)
            {
                queryParameters[parameter.Key] = parameter.Value;
            }

            return queryParameters.ToString();
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

            /// <summary>
            /// Generates an access token. Calls the generateAccessToken API  (https://github.com/Azure/azure-rest-api-specs/blob/main/specification/vi/resource-manager/Microsoft.VideoIndexer/stable/2022-08-01/vi.json#:~:text=%22/subscriptions/%7BsubscriptionId%7D/resourceGroups/%7BresourceGroupName%7D/providers/Microsoft.VideoIndexer/accounts/%7BaccountName%7D/generateAccessToken%22%3A%20%7B)
            /// </summary>
            /// <param name="permission"> The permission for the access token</param>
            /// <param name="scope"> The scope of the access token </param>
            /// <param name="videoId"> if the scope is video, this is the video Id </param>
            /// <param name="projectId"> If the scope is project, this is the project Id </param>
            /// <returns> The access token, otherwise throws an exception</returns>
            public async Task<string> GetAccessToken(ArmAccessTokenPermission permission, ArmAccessTokenScope scope, string videoId = null, string projectId = null)
            {
                var accessTokenRequest = new AccessTokenRequest
                {
                    PermissionType = permission,
                    Scope = scope,
                    VideoId = videoId,
                    ProjectId = projectId
                };

                Console.WriteLine($"\nGetting access token: {JsonSerializer.Serialize(accessTokenRequest)}");

                // Set the generateAccessToken (from video indexer) http request content
                try
                {
                    var jsonRequestBody = JsonSerializer.Serialize(accessTokenRequest);
                    var httpContent = new StringContent(jsonRequestBody, System.Text.Encoding.UTF8, "application/json");

                    // Set request uri
                    var requestUri = $"{AzureResourceManager}/subscriptions/{SubscriptionId}/resourcegroups/{ResourceGroup}/providers/Microsoft.VideoIndexer/accounts/{AccountName}/generateAccessToken?api-version={ApiVersion}";
                    var client = new HttpClient(new HttpClientHandler());
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", armAccessToken);

                    var result = await client.PostAsync(requestUri, httpContent);

                    VerifyStatus(result, System.Net.HttpStatusCode.OK);
                    var jsonResponseBody = await result.Content.ReadAsStringAsync();
                    Console.WriteLine($"Got access token: {scope} {videoId}, {permission}");
                    return JsonSerializer.Deserialize<GenerateAccessTokenResponse>(jsonResponseBody).AccessToken;
                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex.ToString());
                    throw;
                }
            }

            /// <summary>
            /// Gets an account. Calls the getAccount API (https://github.com/Azure/azure-rest-api-specs/blob/main/specification/vi/resource-manager/Microsoft.VideoIndexer/stable/2022-08-01/vi.json#:~:text=%22/subscriptions/%7BsubscriptionId%7D/resourceGroups/%7BresourceGroupName%7D/providers/Microsoft.VideoIndexer/accounts/%7BaccountName%7D%22%3A%20%7B)
            /// </summary>
            /// <returns> The Account, otherwise throws an exception</returns>
            public async Task<Account> GetAccount()
            {
                Console.WriteLine($"Getting account {AccountName}.");
                Account account;
                try
                {
                    // Set request uri
                    var requestUri = $"{AzureResourceManager}/subscriptions/{SubscriptionId}/resourcegroups/{ResourceGroup}/providers/Microsoft.VideoIndexer/accounts/{AccountName}?api-version={ApiVersion}";
                    var client = new HttpClient(new HttpClientHandler());
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", armAccessToken);

                    var result = await client.GetAsync(requestUri);

                    VerifyStatus(result, System.Net.HttpStatusCode.OK);
                    var jsonResponseBody = await result.Content.ReadAsStringAsync();
                    account = JsonSerializer.Deserialize<Account>(jsonResponseBody);
                    VerifyValidAccount(account);
                    Console.WriteLine($"The account ID is {account.Properties.Id}");
                    Console.WriteLine($"The account location is {account.Location}");
                    return account;
                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex.ToString());
                    throw;
                }
            }

            private static void VerifyValidAccount(Account account)
            {
                if (string.IsNullOrWhiteSpace(account.Location) || account.Properties == null || string.IsNullOrWhiteSpace(account.Properties.Id))
                {
                    Console.WriteLine($"{nameof(AccountName)} {AccountName} not found. Check {nameof(SubscriptionId)}, {nameof(ResourceGroup)}, {nameof(AccountName)} ar valid.");
                    throw new Exception($"Account {AccountName} not found.");
                }
            }
        }

        public class AccessTokenRequest
        {
            [JsonPropertyName("permissionType")]
            public ArmAccessTokenPermission PermissionType { get; set; }

            [JsonPropertyName("scope")]
            public ArmAccessTokenScope Scope { get; set; }

            [JsonPropertyName("projectId")]
            public string ProjectId { get; set; }

            [JsonPropertyName("videoId")]
            public string VideoId { get; set; }
        }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public enum ArmAccessTokenPermission
        {
            Reader,
            Contributor,
            MyAccessAdministrator,
            Owner,
        }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public enum ArmAccessTokenScope
        {
            Account,
            Project,
            Video
        }

        public class GenerateAccessTokenResponse
        {
            [JsonPropertyName("accessToken")]
            public string AccessToken { get; set; }
        }

        public class AccountProperties
        {
            [JsonPropertyName("accountId")]
            public string Id { get; set; }
        }

        public class Account
        {
            [JsonPropertyName("properties")]
            public AccountProperties Properties { get; set; }

            [JsonPropertyName("location")]
            public string Location { get; set; }
        }

        public class Video
        {
            [JsonPropertyName("id")]
            public string Id { get; set; }

            [JsonPropertyName("state")]
            public string State { get; set; }
        }

        public enum ProcessingState
        {
            Uploaded,
            Processing,
            Processed,
            Failed
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
