using System.Text;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using VideoIndexerClient.auth;
using VideoIndexerClient.model;
using VideoIndexerClient.Utils;
using static VideoIndexerClient.Utils.Consts;
using JsonSerializer = System.Text.Json.JsonSerializer;

namespace VideoIndexerClient
{
    public class VideoIndexerClient
    {
        private HttpClient _httpClient;
        private string _accountAccessToken;
        private readonly Account _account;
        private readonly ILogger _logger;


        public VideoIndexerClient(ILogger logger, Account account = null)
        {
            System.Net.ServicePointManager.SecurityProtocol |= System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls13;
            _logger = logger;
            _account = account;
        }

        public async Task Authenticate(string? accessToken)
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

        /// <summary>
        /// Uploads a video and starts the video index. Calls the uploadVideo API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video)
        /// </summary>
        /// <param name="videoUrl"> Link To Publicy Accessed Video URL</param>
        /// <param name="videoName"> The Asset name to be used </param>
        /// <param name="exludedAIs"> The ExcludeAI list to run </param>
        /// <param name="waitForIndex"> should this method wait for index operation to complete </param>
        /// <returns> Video Id of the video being indexed, otherwise throws excpetion</returns>
        public async Task<string> UploadUrl(string videoUrl, string videoName)
        {
            if (_account == null)
            {
                throw new Exception("Call Get Account Details First");
            }

            _logger.LogInformation("Video for account {0} is starting to upload.", _account.Properties.Id);
            var content = new MultipartFormDataContent();

            try
            {
                //Build Query Parameter Dictionary
                var queryDictionary = new Dictionary<string, string>
                {
                    { "accessToken", _accountAccessToken },
                    { "name", videoName },
                    { "description", "video_description" },
                    { "privacy", "private" },
                    { "partition", "partition" }
                };

                if (!string.IsNullOrEmpty(videoUrl) && Uri.IsWellFormedUriString(videoUrl, UriKind.Absolute))
                {
                    _logger.LogInformation("Using public video url For upload.");
                    queryDictionary.Add("videoUrl", videoUrl);
                }
                else
                {
                    throw new ArgumentException("VideoUrl or LocalVidePath are invalid");
                }
                var queryParams = queryDictionary.CreateQueryString();

                // Send POST request
                var url = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos?{queryParams}";
                var uploadRequestResult = await _httpClient.PostAsync(url, content);
                uploadRequestResult.VerifyStatus(System.Net.HttpStatusCode.OK);
                var uploadResult = await uploadRequestResult.Content.ReadAsStringAsync();

                // Get the video ID from the upload result
                var videoId = JsonSerializer.Deserialize<Video>(uploadResult).Id;
                _logger.LogInformation("Video ID {0} was uploaded successfully", videoId);
                return videoId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Could Not Upload from Shared Url");
                throw;
            }
        }

        public async Task<string> GetIndex(string videoId)
        {
            var queryParams = new Dictionary<string, string>
            {
                { "language", "en-US" },
                { "accessToken", _accountAccessToken }

            }.CreateQueryString();

            var requestUrl = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/Index?{queryParams}";
            var indexResponse = await _httpClient.GetAsync(requestUrl);
            indexResponse.VerifyStatus(System.Net.HttpStatusCode.OK);
            var indexResult = await indexResponse.Content.ReadAsStringAsync();

            Console.WriteLine(indexResult);
            return indexResult;
        }

        public async Task<List<FrameUriData>> GetVideoFrames(string videoId)
        {
            var frames = new List<FrameUriData>();
            var pageSize = 1000;
            var skip = 0;
            var done = false; 

            while (!done)
            {
                var page = await GetVideoFramesAsPages(videoId, pageSize, skip);
                done = page.NextPage.Done;
                skip += pageSize;
                frames.AddRange(page.Results);
            }
            return frames; 

        }

        public async Task<FramesUrisResult> GetVideoFramesAsPages(string videoId, int ? pageSize, int ? skip)
        {
            var queryParams = new Dictionary<string, string>
            {
                { "language", "en-US" },
                { "urlsLifetimeSeconds", "3600"},
                { "accessToken", _accountAccessToken }
            };

            if (pageSize.HasValue)
            {
                queryParams.Add("pageSize", pageSize.Value.ToString());
            }

            if (skip.HasValue)
            {
                queryParams.Add("skip", skip.Value.ToString());
            }

            var queryParamsString = queryParams.CreateQueryString();
            var requestUrl = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/FramesFilePaths?{queryParamsString}";
            var framesResponse = await _httpClient.GetAsync(requestUrl);
            framesResponse.VerifyStatus(System.Net.HttpStatusCode.OK);
            var framesResult = await framesResponse.Content.ReadAsStringAsync();
            return JsonConvert.DeserializeObject<FramesUrisResult>(framesResult);
        }

        /// <summary>
        /// Get Video Artifact 
        /// </summary>
        /// <param name="videoId">video Id</param>
        /// <param name="artifactType">DetectedObject,OCR , etc</param>
        /// <returns></returns>
        public async Task<Artifact?> GetVideoArtifacts(string videoId,string artifactType)
        {
            Console.WriteLine($"Dowload video Artifcats on Account {_account.Properties.Id} for video ID {videoId}.");
            var queryParams = new Dictionary<string, string>()
            {
                { "accessToken" , _accountAccessToken },
                {"type", artifactType}
            }.CreateQueryString();

            try
            {
                //Step 1 : Get the download Artifact SAS URL
                var requestUrl = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/ArtifactUrl?{queryParams}";
                using var searchRequestResult = await _httpClient.GetAsync(requestUrl);
                searchRequestResult.EnsureSuccessStatusCode();
                var artifactDownlaodSasUrl = (await searchRequestResult.Content.ReadAsStringAsync()).Replace("\"", string.Empty);

                //Step 2 : Download the Artifacts URL 
                using var response = await _httpClient.GetAsync(artifactDownlaodSasUrl, HttpCompletionOption.ResponseHeadersRead);
                var artifactJsonData = await response.Content.ReadAsStringAsync();
                return JsonConvert.DeserializeObject<Artifact>(artifactJsonData);
                
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,"Could not Fetch Artifact Data on video {0} for artifact type {1}",videoId,artifactType);
                Console.WriteLine(ex.ToString());
            }

            return null;
        }


        public async Task<string> PatchIndex(string videoId, CustomInsights jsonPayload, string embeddedPath = DEFAULT_EMBEDDED_PATH)
        {
            var queryParams = new Dictionary<string, string>
            {
                { "accessToken", _accountAccessToken },
            }.CreateQueryString();

            var insights = new CustomInsights[] { jsonPayload };
            var requestUrl = $"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/Index?{queryParams}";
            var pathResponse = await _httpClient.PatchAsync(requestUrl, BuildFlorenceEnrichContent(insights, embeddedPath));
            var res = pathResponse.Content.ReadAsStringAsync();
            pathResponse.VerifyStatus(System.Net.HttpStatusCode.OK);
            return pathResponse.StatusCode.ToString();
        }

        private static HttpContent BuildFlorenceEnrichContent(CustomInsights[] florenceResponse, string embeddedPath)
        {
            var operation = "add";
            var wrapper = new List<object>
            {
                new
                {
                    value = florenceResponse,
                    path = embeddedPath,
                    op = operation
                }
            };

            var jsonPayload = JsonConvert.SerializeObject(wrapper);
            return new StringContent(jsonPayload, Encoding.UTF8, "application/json");
        }
    }
}
