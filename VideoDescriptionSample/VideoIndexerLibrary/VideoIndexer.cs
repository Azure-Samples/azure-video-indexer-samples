// This class takes care of Video Indexer API calls
//
//

using System;
using System.Net.Http;
using System.Threading.Tasks;
using System.IO;
using System.Collections.Generic;
using System.Web;
using System.Globalization;
using System.Collections.Specialized;

namespace VideoIndexerLibrary
{

    public class VideoIndexer
    {
        private static HttpClientHandler _handler = new HttpClientHandler() { AllowAutoRedirect = false };
        private static HttpClient _client = new HttpClient(_handler);
        private static NameValueCollection _queryString = HttpUtility.ParseQueryString(string.Empty);

        private const string apiUrl = "https://api.videoindexer.ai";

        private string _accountId;
        private string _location;
        private string _subscriptionKey;
        private Dictionary<string, VideoIndexerVideoToken> _videoAccessTokens = new Dictionary<string, VideoIndexerVideoToken>();

        /// <summary>
        /// Initialize the Video Indexer library
        /// </summary>
        /// <param name="accountId"></param>
        /// <param name="location"></param>
        /// <param name="subscriptionKey"></param>
        public VideoIndexer(string accountId, string location, string subscriptionKey)
        {
            _accountId = accountId;
            _location = location;
            _subscriptionKey = subscriptionKey;
        }


        /// <summary>
        /// Get a Video Indexer account token
        /// </summary>
        /// <returns></returns>
        public async Task<string> GetAccountAccessTokenAsync()
        {
            return await GetAccessTokenAsync($"{apiUrl}/auth/{_location}/Accounts/{_accountId}/AccessToken?allowEdit=true").ConfigureAwait(false);
        }

        /// <summary>
        /// Get a Video access token for a specific video
        /// </summary>
        /// <param name="videoId"></param>
        /// <returns></returns>
        public async Task<string> GetVideoAccessTokenAsync(string videoId)
        {
            if (!_videoAccessTokens.ContainsKey(videoId) || _videoAccessTokens[videoId].expirationTime >= DateTime.Now.AddMinutes(-5))
            {
                // no token or expired token
                string token = await GetAccessTokenAsync($"{apiUrl}/auth/{_location}/Accounts/{_accountId}/Videos/{videoId}/AccessToken?allowEdit=true").ConfigureAwait(false);
                _videoAccessTokens[videoId] = new VideoIndexerVideoToken() { token = token, expirationTime = DateTime.Now.AddMinutes(60) }; // token is valid one hour
            }
            return _videoAccessTokens[videoId].token;
        }

        /// <summary>
        /// Get the JSON Insights data for a specific video
        /// </summary>
        /// <param name="videoId"></param>
        /// <returns></returns>
        public async Task<string> GetInsightsAsync(string videoId)
        {
            _queryString.Clear();
            _queryString["accessToken"] = await GetVideoAccessTokenAsync(videoId).ConfigureAwait(false);
            Uri requestUri = new Uri($"{apiUrl}/{_location}/Accounts/{_accountId}/Videos/{videoId}/Index?{_queryString}");

            HttpResponseMessage insightsRequestResult = await _client.GetAsync(requestUri).ConfigureAwait(false);

            if (!insightsRequestResult.IsSuccessStatusCode)
            {
                throw new Exception(insightsRequestResult.ReasonPhrase);
            }

            return await insightsRequestResult.Content.ReadAsStringAsync().ConfigureAwait(false);
        }

        /// <summary>
        /// Get a specific Thumbnail for a specific video
        /// </summary>
        /// <param name="videoId"></param>
        /// <param name="thumbnailId"></param>
        /// <returns></returns>
        public async Task<Stream> GetVideoThumbnailAsync(string videoId, string thumbnailId)
        {
            _queryString.Clear();
            _queryString["accessToken"] = await GetVideoAccessTokenAsync(videoId).ConfigureAwait(false);
            _queryString["format"] = "Jpeg";
            Uri requestUri = new Uri($"{apiUrl}/{_location}/Accounts/{_accountId}/Videos/{videoId}/Thumbnails/{thumbnailId}?{_queryString}");

            HttpResponseMessage thumbnailRequestResult = await _client.GetAsync(requestUri).ConfigureAwait(false);

            if (!thumbnailRequestResult.IsSuccessStatusCode)
            {
                throw new Exception(thumbnailRequestResult.ReasonPhrase);
            }

            return await thumbnailRequestResult.Content.ReadAsStreamAsync().ConfigureAwait(false);
        }

        /// <summary>
        /// Get the Player Widget URL for a specific video
        /// </summary>
        /// <param name="videoId"></param>
        /// <returns></returns>
        public async Task<Uri> GetPlayerWidgetAsync(string videoId)
        {
            _queryString.Clear();
            return await GetWidgetAsync(videoId, "PlayerWidget").ConfigureAwait(false);
        }

        /// <summary>
        /// Get the Video Insights Widget URL for a specific video
        /// </summary>
        /// <param name="videoId"></param>
        /// <param name="allowEdit"></param>
        /// <returns></returns>
        public async Task<Uri> GetVideoInsightsWidgetAsync(string videoId, bool allowEdit)
        {
            _queryString.Clear();
            _queryString["allowEdit"] = allowEdit.ToString(CultureInfo.InvariantCulture);

            return await GetWidgetAsync(videoId, "InsightsWidget").ConfigureAwait(false);
        }

        private async Task<Uri> GetWidgetAsync(string videoId, string widgetApiStr)
        {
            _queryString["accessToken"] = await GetVideoAccessTokenAsync(videoId).ConfigureAwait(false);

            Uri requestUri = new Uri($"{apiUrl}/{_location}/Accounts/{_accountId}/Videos/{videoId}/{widgetApiStr}?{_queryString}");

            HttpResponseMessage insightsRequestResult = await _client.GetAsync(requestUri).ConfigureAwait(false);

            if (insightsRequestResult.StatusCode == System.Net.HttpStatusCode.MovedPermanently)
            {
                return insightsRequestResult.Headers.Location;
            }
            else
            {
                throw new Exception(insightsRequestResult.ReasonPhrase);
            }
        }

        private async Task<string> GetAccessTokenAsync(string requestUrl)
        {
            // Request headers
            _client.DefaultRequestHeaders.Add("x-ms-client-request-id", "");
            _client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", _subscriptionKey);

            var requestResult = await _client.GetAsync(new Uri(requestUrl)).ConfigureAwait(false);

            if (!requestResult.IsSuccessStatusCode)
            {
                throw new Exception(requestResult.ReasonPhrase);
            }
            _client.DefaultRequestHeaders.Remove("Ocp-Apim-Subscription-Key");

            return (await requestResult.Content.ReadAsStringAsync().ConfigureAwait(false)).Replace("\"", "");
        }
    }
}