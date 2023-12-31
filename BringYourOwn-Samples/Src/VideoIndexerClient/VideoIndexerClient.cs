using System.Text;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using VideoIndexerClient.auth;
using VideoIndexerClient.model;
using VideoIndexerClient.Utils;
using static VideoIndexerClient.Utils.Consts;
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.

namespace VideoIndexerClient
{
    public class VideoIndexerClient
    {
        private HttpClient _httpClient;
        private string _accountAccessToken;
        private readonly Account _account;
        private readonly ILogger _logger;
        
        public VideoIndexerClient(ILogger logger, Account account)
        {
            System.Net.ServicePointManager.SecurityProtocol |= System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls13;
            _account = account;
            _logger = logger;
        }

        public async Task Authenticate(string? accessToken = null)
        {
            try
            {
                if (string.IsNullOrEmpty(accessToken))
                    _accountAccessToken = await AccountTokenProvider.GetAccountAccessTokenAsync(_logger);
                else
                    _accountAccessToken = accessToken;
                _httpClient = HttpClientUtils.CreateHttpClient(accessToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Could Not Authenticate VI Client");
                throw;
            }
        }


        public string GetThumbnailRequestUri(string videoId, string thumbnailId)
        {
            try
            {
                _logger.LogInformation("Getting Thumbnail {0} for Video {1}",videoId,thumbnailId);
                var requestUrl = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/Thumbnails/{thumbnailId}?{GetQueryParams()}";
                return requestUrl;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,"Could not Get Thumbail from Server. videoId: {0}, thumbnailId: {1}", videoId,thumbnailId);
            }
            return string.Empty;
        }

        public async Task<Insights?> GetVideoIndexInsights(string videoId)
        {
            try
            {
                var requestUrl = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/Index?{GetQueryParams()}";
                var videoGetIndexRequestResult = await _httpClient.GetAsync(requestUrl);
                videoGetIndexRequestResult.VerifyStatus(System.Net.HttpStatusCode.OK);
                var videoGetIndexResult = await videoGetIndexRequestResult.Content.ReadAsStringAsync();
                return JsonConvert.DeserializeObject<Insights>(videoGetIndexResult);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Could not Get Video Index Insights. videoId: {0}",videoId);
            }

            return null;
        }

        

        public async Task<string> PatchIndex(string videoId, CustomInsights customInsights, bool customInsightsAlreadyExists = false, string embeddedPath = DEFAULT_EMBEDDED_PATH)
        {
            //Prepare the Payload request 
            var requestUrl = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/Index?{GetQueryParams()}";
            var wrapper = new List<object>
            {
                new
                {
                    op = customInsightsAlreadyExists ? "replace" : "add",
                    value = new[] { customInsights },
                    path = embeddedPath,
                }
            };

            var jsonPayload = JsonConvert.SerializeObject(wrapper);
            var patchContent = new  StringContent(jsonPayload, Encoding.UTF8, "application/json");

            var pathResponse = await _httpClient.PatchAsync(requestUrl, patchContent);
            pathResponse.VerifyStatus(System.Net.HttpStatusCode.OK);
            return pathResponse.StatusCode.ToString();
        }

        private string GetQueryParams()
        {
            return new Dictionary<string, string>()
            {
                { "accessToken", _accountAccessToken },
                { "language", "English" },
                { "format" , "Jpeg "}
            }.CreateQueryString();
        }
    }
}
