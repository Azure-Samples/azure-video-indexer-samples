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
        private const string ApiVersion = "2021-11-10-preview";
        private const string AzureResourceManager = "https://management.azure.com";
        private const string SubscriptionId = "<Your SubscriptionId>";
        private const string ResourceGroup = "<Your Resource Group>";
        private const string AccountName = "<Your Acocunt Name>";
        private const string VideoUrl = "<Your Video Url>";

        public static async Task Main(string[] args)
        {
            Console.WriteLine($"getting account data for {AccountName} {Environment.NewLine} hi");
            // Build Azure Video Analyzer for Media resource provider client that has access token throuhg ARM
            var videoIndexerResourceProviderClient = await VideoIndexerResourceProviderClient.BuildVideoIndexerResourceProviderClient();

            // Get account details
            var account = await videoIndexerResourceProviderClient.GetAccount();
            var accountLocation = account.Location;
            var accountId = account.Properties.Id;

            // Get account level access token for Azure Video Analyzer for Media 
            var accountAccessToken = await videoIndexerResourceProviderClient.GetAccessToken(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Account);

            var apiUrl = "https://api.videoindexer.ai";
            System.Net.ServicePointManager.SecurityProtocol = System.Net.ServicePointManager.SecurityProtocol | System.Net.SecurityProtocolType.Tls12;

            // Create the http client
            var handler = new HttpClientHandler
            {
                AllowAutoRedirect = false
            };
            var client = new HttpClient(handler);

            // Upload a video
            var videoId = await UploadVideo(accountId, accountLocation, accountAccessToken, apiUrl, client);

            // Wait for the video index to finish
            await WaitForIndex(accountId, accountLocation, accountAccessToken, apiUrl, client, videoId);

            // Get video level access token for Azure Video Analyzer for Media 
            var videoAccessToken = await videoIndexerResourceProviderClient.GetAccessToken(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Video, videoId);

            // Search for the video
            await GetVideo(accountId, accountLocation, apiUrl, client, videoId, videoAccessToken);

            // Get insights widget url
            await GetInsightsWidgetUrl(accountId, accountLocation, apiUrl, client, videoId, videoAccessToken);

            // Get player widget url
            await GetPlayerWidgetUrl(accountId, accountLocation, apiUrl, client, videoId, videoAccessToken);
        }

        private static async Task<string> UploadVideo(string accountId, string accountLocation, string acountAccessToken, string apiUrl, HttpClient client)
        {
            var content = new MultipartFormDataContent();
            Console.WriteLine("Uploading...");

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

                // For more info on this API see API portal (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video)
                var uploadRequestResult = await client.PostAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos?{queryParams}", content);
                VerifyStatus(uploadRequestResult);
                var uploadResult = await uploadRequestResult.Content.ReadAsStringAsync();

                // Get the video ID from the upload result
                var videoId = JsonSerializer.Deserialize<Video>(uploadResult).Id;
                Console.WriteLine("Uploaded");
                Console.WriteLine("Video ID:");
                Console.WriteLine(videoId);
                return videoId;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
                throw;
            }
        }

        private static async Task WaitForIndex(string accountId, string accountLocation, string acountAccessToken, string apiUrl, HttpClient client, string videoId)
        {
            string queryParams;
            while (true)
            {
                await Task.Delay(10000);

                queryParams = CreateQueryString(
                    new Dictionary<string, string>()
                    {
                            {"accessToken", acountAccessToken},
                            {"language", "English"},
                    });

                // For more info on this API see API portal (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Index)
                var videoGetIndexRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/{videoId}/Index?{queryParams}");

                VerifyStatus(videoGetIndexRequestResult);
                var videoGetIndexResult = await videoGetIndexRequestResult.Content.ReadAsStringAsync();
                string processingState = JsonSerializer.Deserialize<Video>(videoGetIndexResult).State;
                Console.WriteLine("");
                Console.WriteLine("State:");
                Console.WriteLine(processingState);

                // Job is finished
                if (processingState != "Uploaded" && processingState != "Processing")
                {
                    Console.WriteLine("");
                    Console.WriteLine("Full JSON:");
                    Console.WriteLine(videoGetIndexResult);
                    return;
                }
            }
        }

        private static async Task GetVideo(string accountId, string accountLocation, string apiUrl, HttpClient client, string videoId, string videoAccessToken)
        {
            var queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                        {"accessToken", videoAccessToken},
                        {"id", videoId},
                });

            try
            {
                // For more info on this API see API portal (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Search-Videos)
                var searchRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/Search?{queryParams}");

                VerifyStatus(searchRequestResult);
                var searchResult = await searchRequestResult.Content.ReadAsStringAsync();
                Console.WriteLine("");
                Console.WriteLine("Search:");
                Console.WriteLine(searchResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }

        private static async Task GetInsightsWidgetUrl(string accountId, string accountLocation, string apiUrl, HttpClient client, string videoId, string videoAccessToken)
        {
            var queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                    {"accessToken", videoAccessToken},
                    {"widgetType", "Keywords"},
                    {"allowEdit", "true"},
                });
            try
            {
                // For more info on this API see API portal (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Insights-Widget)
                var insightsWidgetRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/{videoId}/InsightsWidget?{queryParams}");

                VerifyStatus(insightsWidgetRequestResult, System.Net.HttpStatusCode.MovedPermanently);
                var insightsWidgetLink = insightsWidgetRequestResult.Headers.Location;
                Console.WriteLine("");
                Console.WriteLine("Insights Widget url:");
                Console.WriteLine(insightsWidgetLink);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }

        private static async Task GetPlayerWidgetUrl(string accountId, string accountLocation, string apiUrl, HttpClient client, string videoId, string videoAccessToken)
        {
            var queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                    {"accessToken", videoAccessToken},
                });

            try
            {
                // For more info on this API see API portal (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Player-Widget)
                var playerWidgetRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/{videoId}/PlayerWidget?{queryParams}");

                var playerWidgetLink = playerWidgetRequestResult.Headers.Location;
                VerifyStatus(playerWidgetRequestResult, System.Net.HttpStatusCode.MovedPermanently);
                Console.WriteLine("");
                Console.WriteLine("Player Widget url:");
                Console.WriteLine(playerWidgetLink);
                Console.WriteLine("\nPress Enter to exit...");
                String line = Console.ReadLine();
                if (line == "enter")
                {
                    System.Environment.Exit(0);
                }
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

            public async Task<string> GetAccessToken(ArmAccessTokenPermission permission, ArmAccessTokenScope scope, string videoId = null, string projectId = null)
            {
                var accessTokenRequest = new AccessTokenRequest
                {
                    PermissionType = permission,
                    Scope = scope,
                    VideoId = videoId,
                    ProjectId = projectId
                };

                Console.WriteLine($"Getting access token. {JsonSerializer.Serialize(accessTokenRequest)}");

                // Set the generateAccessToken (from video indexer) http request content
                try
                {
                    var jsonRequestBody = JsonSerializer.Serialize(accessTokenRequest);
                    var httpContent = new StringContent(jsonRequestBody, System.Text.Encoding.UTF8, "application/json");

                    // Set request uri
                    var requestUri = $"{AzureResourceManager}/subscriptions/{SubscriptionId}/resourcegroups/{ResourceGroup}/providers/Microsoft.VideoIndexer/accounts/{AccountName}/generateAccessToken?api-version={ApiVersion}";
                    var client = new HttpClient(new HttpClientHandler());
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", armAccessToken);

                    //Generate ARM access token - for more info on this API see https://github.com/Azure/azure-rest-api-specs/blob/main/specification/vi/resource-manager/Microsoft.VideoIndexer/preview/2021-11-10-preview/vi.json#:~:text=%22/subscriptions/%7BsubscriptionId%7D/resourceGroups/%7BresourceGroupName%7D/providers/Microsoft.VideoIndexer/accounts/%7BaccountName%7D/generateAccessToken%22%3A%20%7B
                    var result = await client.PostAsync(requestUri, httpContent);

                    VerifyStatus(result);
                    var jsonResponseBody = await result.Content.ReadAsStringAsync();
                    return JsonSerializer.Deserialize<GenerateAccessTokenResponse>(jsonResponseBody).AccessToken;
                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex.ToString());
                    throw;
                }
            }

            public async Task<Account> GetAccount()
            {
                Console.WriteLine($"Getting account.");
                Account account;
                try
                {
                    // Set request uri
                    var requestUri = $"{AzureResourceManager}/subscriptions/{SubscriptionId}/resourcegroups/{ResourceGroup}/providers/Microsoft.VideoIndexer/accounts/{AccountName}?api-version={ApiVersion}";
                    var client = new HttpClient(new HttpClientHandler());
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", armAccessToken);

                    //Get ARM account - for more info on this API see https://github.com/Azure/azure-rest-api-specs/blob/main/specification/vi/resource-manager/Microsoft.VideoIndexer/preview/2021-11-10-preview/vi.json#:~:text=%22/subscriptions/%7BsubscriptionId%7D/resourceGroups/%7BresourceGroupName%7D/providers/Microsoft.VideoIndexer/accounts/%7BaccountName%7D%22%3A%20%7B
                    var result = await client.GetAsync(requestUri);

                    VerifyStatus(result);
                    var jsonResponseBody = await result.Content.ReadAsStringAsync();
                    account = JsonSerializer.Deserialize<Account>(jsonResponseBody);
                    VerifyValidAccount(account);
                    Console.WriteLine($"account id: {account.Properties.Id}");
                    Console.WriteLine($"account location: {account.Location}");
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

        public static void VerifyStatus(HttpResponseMessage response, System.Net.HttpStatusCode excpectedStatusCode = System.Net.HttpStatusCode.OK)
        {
            if (response.StatusCode != excpectedStatusCode)
            {
                throw new Exception(response.ToString());
            }
        }
    }
}
