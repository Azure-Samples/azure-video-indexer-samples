﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;
using VideoIndexerClient;
using static VideoIndexerClient.Consts;
using static VideoIndexingARMAccounts.Program;

namespace VideoIndexingARMAccounts.VideoIndexerClient
{
    public class VideoIndexerClient
    {
        private HttpClient _httpClient;
        private string _armAccessToken;
        private string _accountAccessToken;
        private Account _account;

        private TimeSpan _pollingInteval = TimeSpan.FromSeconds(10);

        public VideoIndexerClient()
        {
            System.Net.ServicePointManager.SecurityProtocol |= System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls13;
            
        }

        public async Task Authenticate()
        {
            try
            {
                _armAccessToken = await AccountTokenProvider.GetArmAccessTokenAsync();
                _accountAccessToken = await AccountTokenProvider.GetAccountAccessTokenAsync(_armAccessToken);
                _httpClient = HttpClientUtils.CreateHttpClient(_accountAccessToken);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Get Information about the Account
        /// </summary>
        /// <param name="accountName"></param>
        /// <returns></returns>
        public async Task<Account> GetAccount(string accountName)
        {
            if (_account != null)
            {
                return _account;
            }
            Console.WriteLine($"Getting account {accountName}.");
            try
            {
                // Set request uri
                var requestUri = $"{AzureResourceManager}/subscriptions/{SubscriptionId}/resourcegroups/{ResourceGroup}/providers/Microsoft.VideoIndexer/accounts/{AccountName}?api-version={ApiVersion}";
                var client = new HttpClient(new HttpClientHandler());
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _armAccessToken);

                var result = await client.GetAsync(requestUri);

                VerifyStatus(result, System.Net.HttpStatusCode.OK);
                var jsonResponseBody = await result.Content.ReadAsStringAsync();
                var account = JsonSerializer.Deserialize<Account>(jsonResponseBody);
                VerifyValidAccount(account, accountName);
                Console.WriteLine($"[Account Details] Id:{account.Properties.Id}, Location: {account.Location}");
                _account = account;
                return account;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
                throw;
            }
        }

        /***
        * UrlUplopad
        ****/
        public async Task<string> UrlUplopad(string videoUrl , string videoName, string exludedAIs = null, bool waitForIndex = false )
        {
            if (_account == null)
            {
                throw new Exception("Call Get Account Details First");
            }

            Console.WriteLine($"Video for account {_account.Properties.Id} is starting to upload.");
            var content = new MultipartFormDataContent();
            FileStream fileStream = null;
            StreamContent streamContent = null;
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
                    Console.WriteLine("Using publiuc video url For upload.");
                    queryDictionary.Add("videoUrl", videoUrl);
                }
                /*else if (File.Exists(LocalVideoPath))
                {
                    Console.WriteLine("Using local video Multipart upload.");
                    // Add file content
                    fileStream = new FileStream(LocalVideoPath, FileMode.Open, FileAccess.Read);
                    streamContent = new StreamContent(fileStream);
                    content.Add(streamContent, "fileName", Path.GetFileName(LocalVideoPath));
                    streamContent.Headers.Add("Content-Type", "multipart/form-data");
                    streamContent.Headers.Add("Content-Length", fileStream.Length.ToString());
                }*/
                else
                {
                    throw new ArgumentException("VideoUrl or LocalVidePath are invalid");
                }
                var queryParams = queryDictionary.CreateQueryString();
                if (!string.IsNullOrEmpty(exludedAIs))
                    queryParams += AddExcludedAIs(exludedAIs);

                // Send POST request
                var uploadRequestResult = await _httpClient.PostAsync($"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos?{queryParams}", content);
                VerifyStatus(uploadRequestResult, System.Net.HttpStatusCode.OK);
                var uploadResult = await uploadRequestResult.Content.ReadAsStringAsync();

                // Get the video ID from the upload result
                var videoId = JsonSerializer.Deserialize<Video>(uploadResult).Id;
                Console.WriteLine($"Video ID {videoId} was uploaded successfully");
                
                if (waitForIndex)
                {
                    Console.WriteLine("Waiting for Index Operation to Complete");
                    await WaitForIndex(videoId);
                }
                return videoId;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
                throw;
            }
            finally
            {
                await fileStream.DisposeAsync();
                streamContent.Dispose();
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
        private async Task WaitForIndex(string videoId)
        {
            Console.WriteLine($"Waiting for video {videoId} to finish indexing.");
            string queryParams;
            while (true)
            {
                queryParams = new Dictionary<string, string>()
                {
                    {"accessToken", _accountAccessToken},
                    {"language", "English"},
                }.CreateQueryString();

                var videoGetIndexRequestResult = await _httpClient.GetAsync($"{ApiEndpoint}/{_account.Location}/Accounts/{_account.Properties.Id}/Videos/{videoId}/Index?{queryParams}");
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
                    Console.WriteLine($"The video index failed for video ID {videoId}.");
                    throw new Exception(videoGetIndexResult);
                }

                // Job hasn't finished
                Console.WriteLine($"The video index state is {processingState}");
                await Task.Delay(_pollingInteval);
            }
        }

        public async Task<string> FileUpload(string videoName,  string mediaPath, string callbackUrl, string clientRequestId)
        {
            var url = $"{ApiEndpoint}/Accounts/{ViAccountId}/Videos?name={videoName}&callbackurl={callbackUrl}";
            // Create multipart form data content
            if (!File.Exists(mediaPath))
                throw new Exception($"Could not find file at path {mediaPath}");
            var response = await _httpClient.FileUpload(url, mediaPath, clientRequestId);
            return response;
        }

        private string AddExcludedAIs(string ExcludedAI)
        {
            if (string.IsNullOrEmpty(ExcludedAI))
            {
                return "";
            }
            var list = ExcludedAI.Split(',');
            return list.Aggregate("", (current, item) => current + ("&ExcludedAI=" + item));
        }

        private static void VerifyValidAccount(Account account,string accountName)
        {
            if (string.IsNullOrWhiteSpace(account.Location) || account.Properties == null || string.IsNullOrWhiteSpace(account.Properties.Id))
            {
                Console.WriteLine($"{nameof(accountName)} {accountName} not found. Check {nameof(SubscriptionId)}, {nameof(ResourceGroup)}, {nameof(AccountName)} ar valid.");
                throw new Exception($"Account {accountName} not found.");
            }
        }


    }
}