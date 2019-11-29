// This class takes care of Video Indexer API calls
//
//

using System;
using System.Net.Http;
using System.Threading.Tasks;
using System.IO;
using System.Collections.Generic;

namespace VideoDescription.CognitiveServices
{
    internal class VideoIndexerVideoToken
    {
        public string token { get; set; }
        public DateTime expirationTime { get; set; }
    }

    public class VideoIndexer
    {
        private string _accountId;
        private string _location;
        private string _subscriptionKey;
        private static HttpClientHandler handler = new HttpClientHandler() { AllowAutoRedirect = false };
        private static HttpClient client = new HttpClient(handler);
        private const string apiUrl = "https://api.videoindexer.ai";
        private Dictionary<string, VideoIndexerVideoToken> videoAccessTokens = new Dictionary<string, VideoIndexerVideoToken>();


        public VideoIndexer(string accountId, string location, string subscriptionkey)
        {
            _accountId = accountId;
            _location = location;
            _subscriptionKey = subscriptionkey;
        }


        public async Task<string> GetAccountAccessTokenAsync()
        {
            return await GetAccessTokenAsync($"{apiUrl}/auth/{_location}/Accounts/{_accountId}/AccessToken?allowEdit=true").ConfigureAwait(false);
        }


        public async Task<string> GetVideoAccessTokenAsync(string videoId)
        {
            if (videoAccessTokens.ContainsKey(videoId) && videoAccessTokens[videoId].expirationTime < DateTime.Now.AddMinutes(-5))
            {
                // there is already a video access token, let's use it
            }
            else
            {
                // no token or expired token
                string token = await GetAccessTokenAsync($"{apiUrl}/auth/{_location}/Accounts/{_accountId}/Videos/{videoId}/AccessToken?allowEdit=true").ConfigureAwait(false);
                videoAccessTokens[videoId] = new VideoIndexerVideoToken() { token = token, expirationTime = DateTime.Now.AddMinutes(60) }; // token is valid one hour
            }
            return videoAccessTokens[videoId].token;
        }


        private async Task<string> GetAccessTokenAsync(string requestUrl)
        {
            // Request headers
            client.DefaultRequestHeaders.Add("x-ms-client-request-id", "");
            client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", _subscriptionKey);

            var requestResult = await client.GetAsync(new Uri(requestUrl)).ConfigureAwait(false);

            if (!requestResult.IsSuccessStatusCode)
            {
                throw new Exception(requestResult.ReasonPhrase);
            }
            client.DefaultRequestHeaders.Remove("Ocp-Apim-Subscription-Key");

            return (await requestResult.Content.ReadAsStringAsync().ConfigureAwait(false)).Replace("\"", "");
        }


        public async Task<string> GetInsightsAsync(string videoId)
        {
            string videoAccessToken = await GetVideoAccessTokenAsync(videoId).ConfigureAwait(false);
            Uri requestUri = new Uri($"{apiUrl}/{_location}/Accounts/{_accountId}/Videos/{videoId}/Index?accessToken={videoAccessToken}");
            HttpResponseMessage insightsRequestResult = await client.GetAsync(requestUri).ConfigureAwait(false);

            if (!insightsRequestResult.IsSuccessStatusCode)
            {
                throw new Exception(insightsRequestResult.ReasonPhrase);
            }

            return await insightsRequestResult.Content.ReadAsStringAsync().ConfigureAwait(false);
        }


        public async Task<Stream> GetVideoThumbnailAsync(string videoId, string thumbnailId)
        {
            string videoAccessToken = await GetVideoAccessTokenAsync(videoId).ConfigureAwait(false);
            Uri requestUri = new Uri($"{apiUrl}/{_location}/Accounts/{_accountId}/Videos/{videoId}/Thumbnails/{thumbnailId}?format=Jpeg&accessToken={videoAccessToken}");
            HttpResponseMessage thumbnailRequestResult = await client.GetAsync(requestUri).ConfigureAwait(false);

            if (!thumbnailRequestResult.IsSuccessStatusCode)
            {
                throw new Exception(thumbnailRequestResult.ReasonPhrase);
            }

            return await thumbnailRequestResult.Content.ReadAsStreamAsync().ConfigureAwait(false);
        }
    }
}