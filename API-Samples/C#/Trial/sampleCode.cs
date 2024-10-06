public static async Task Sample()
        {
            /*
             * IMPORTANT: This code is not meant for production usage as is, but demonstrates the important aspects
             * of using Video Indexer API to index videos and get their insights, regardless of the C#/.Net production quality aspects
             */

            var apiUrl = "https://api.videoindexer.ai";
            var apiKey = "API_KEY"; // replace with API key taken from https://aka.ms/viapi
            var accountId = "ACCOUNT_ID"; // replace with your VI account id (guid)
            var accountLocation = "trial";

            // TLS 1.2 (or above) is required to send requests
            var httpHandler = new SocketsHttpHandler();
            httpHandler.SslOptions.EnabledSslProtocols |= SslProtocols.Tls12;
           var client = new HttpClient(httpHandler);

            // Obtain account information and access token - access token is required to perform the actual operations with Video Indexer
            string queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                    {"allowEdit", "true"},
                });

            var getAccountsRequest = new HttpRequestMessage(HttpMethod.Get, $"{apiUrl}/auth/{accountLocation}/Accounts/{accountId}/AccessToken?{queryParams}");
            getAccountsRequest.Headers.Add("Ocp-Apim-Subscription-Key", apiKey);
            getAccountsRequest.Headers.Add("x-ms-client-request-id", Guid.NewGuid().ToString()); // Log the request id so you can include it in case you wish to report an issue for API errors or unexpected API behavior
            var result = await client.SendAsync(getAccountsRequest);
            Console.WriteLine("Response id to log: " + result.Headers.GetValues("x-ms-request-id").FirstOrDefault()); // Log the response id so you can include it in case you wish to report an issue for API errors or unexpected API behavior
            var accessToken = (await result.Content.ReadAsStringAsync()).Trim('"'); // The access token is returned as JSON value surrounded by double-quotes

            // Upload and index the video from URL - this is best practice and very robust compared to uploading a video from local file.
            var videoUrl = "VIDEO_URL"; // replace with the video URL, MUST BE HTTPS

            // To receive push notification when indexing completed (succesfully or otherwise) you can provide a callback URL, that will be invoked with the following query string:
            // ?id={video-id}&state={video-state}, where video-state can be one of: Processed/Failed.
            // Production quality notes:
            //  - DO NOT be strict about video-state values, in case in future Video Indexer team decides to send more push notifications before completion.
            //  - At time of writing Video Indexer doesn't send a body in the POST request, but in future may choose to do so; DO NOT be strict about empty body.
            //  - Video Indexer does not log the query string of customer provided URLs, including callback URL, so you may include authentication/authorization parameters so Video Indexer could access your protected endpoint.
            var callbackUrl = "CALLBACK_URL"; // replace with callback URL, MUST BE HTTPS

            queryParams = CreateQueryString(
                new Dictionary<string, string>()
                {
                    {"name", "Sample video name 1"},
                    {"videoUrl", videoUrl},
                    {"description", "This is a sample video description"},
                    //{"callbackUrl", callbackUrl }, // Optional, but best practice to avoid always polling for status.
                    {"privacy", "private"}, // Other option is public and then everyone can access the video without any authentication and no access token required
                });

            var uploadVideoRequest = new HttpRequestMessage(HttpMethod.Post, $"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos?{queryParams}");
            uploadVideoRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken); // Access token is in JWT Bearer format
            uploadVideoRequest.Headers.Add("x-ms-client-request-id", Guid.NewGuid().ToString()); // Log the request id so you can include it in case you wish to report an issue for API errors or unexpected API behavior
            var uploadRequestResult = await client.SendAsync(uploadVideoRequest);
            Console.WriteLine("Response id to log: " + result.Headers.GetValues("x-ms-request-id").FirstOrDefault()); // Log the response id so you can include it in case you wish to report an issue for API errors or unexpected API behavior
            var uploadResultJson = await uploadRequestResult.Content.ReadAsStringAsync();

            // Get the video ID from the upload result, will be used below.
            string videoId = JsonDocument.Parse(uploadResultJson).RootElement.GetProperty("id").GetString();
            Console.WriteLine($"Uploaded, Account id: {accountId}, Video ID: {videoId}");

            /*
             * IMPORTANT: Production handling of push notifications
             * DO NOT assume callback will be called just once - it might be called multiple times or never due to networking errors.
             * Therefore your callback handler should be idempotent, and you should prepare for edge cases where it's not called by
             * polling for video status after some timeout you define for how long you're willing to wait for notification.
             * The following code shows how to poll for video indexing status which you should do for robustness.
             */

            // Wait for the video index to finish, in real production code you probably want to define some timeout, e.g. using cancellation token.
            while (true)
            {
                await Task.Delay(10000); // For production code you are recommended to use Polly for smarter retries (e.g. exponential backoff) which is bundled with .Net Core HttpClient, available as nuget for .Net Framework as well

                queryParams = CreateQueryString(
                    new Dictionary<string, string>()
                    {
                        {"accessToken", accessToken},
                        {"language", "English"},
                    });

                var videoGetIndexRequestResult = await client.GetAsync($"{apiUrl}/{accountLocation}/Accounts/{accountId}/Videos/{videoId}/Index?{queryParams}");
                var videoGetIndexResult = await videoGetIndexRequestResult.Content.ReadAsStringAsync();

                string processingState = JsonDocument.Parse(videoGetIndexResult).RootElement.GetProperty("state").GetString();

                Console.WriteLine("State: " + processingState);

                // Indexing completed
                if (processingState == "Processed" || processingState == "Failed")
                {
                    Console.WriteLine("Full completed index JSON: ");
                    Console.WriteLine(videoGetIndexResult);
                    break;
                }
            }
        }

        private static string CreateQueryString(IDictionary<string, string> parameters)
        {
            var queryParameters = HttpUtility.ParseQueryString(string.Empty);
            foreach (var parameter in parameters)
            {
                queryParameters[parameter.Key] = parameter.Value;
            }

            return queryParameters.ToString();
        }

