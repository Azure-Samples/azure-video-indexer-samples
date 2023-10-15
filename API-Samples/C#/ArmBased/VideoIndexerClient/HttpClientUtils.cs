using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace VideoIndexingARMAccounts.VideoIndexerClient
{
    public static class HttpClientUtils
    {
        public static HttpClient CreateHttpClient(string token)
        {
            var handler = new HttpClientHandler
            {
                AllowAutoRedirect = false,
                ServerCertificateCustomValidationCallback = (_, _, _, _) => true
            };
            var httpClient = new HttpClient(handler);
            httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {token}");
            return httpClient;
        }

        public static async Task<string> FileUpload(this HttpClient client, string url, string filePath, string clientRequestId)
        {
            using var content = new MultipartFormDataContent();
            // Add file content
            await using var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read);
            using var streamContent = new StreamContent(fileStream);
            content.Add(streamContent, "fileName", Path.GetFileName(filePath));
            content.Headers.Add("x-ms-client-request-id", clientRequestId);
            //streamContent.Headers.Add("Content-Type", "multipart/form-data");
            //content.Headers.Add("Content-Length", fileStream.Length.ToString());
            Console.WriteLine(streamContent.ToString());
            // Send POST request
            var response = await client.PostAsync(url, content);
            Console.WriteLine(response.Headers.ToString());
            // Process response
            if (response.IsSuccessStatusCode)
            {
                var responseBody = await response.Content.ReadAsStringAsync();
                return responseBody;
            }
            Console.WriteLine($"Request failed with status code: {response.StatusCode}");
            return response.ToString();
        }

        public static string CreateQueryString(this IDictionary<string, string> parameters)
        {
            var queryParameters = HttpUtility.ParseQueryString(string.Empty);
            foreach (var parameter in parameters)
            {
                queryParameters[parameter.Key] = parameter.Value;
            }
            return queryParameters.ToString();
        }

        public static void VerifyStatus(this HttpResponseMessage response, System.Net.HttpStatusCode excpectedStatusCode)
        {
            if (response.StatusCode != excpectedStatusCode)
            {
                throw new Exception(response.ToString());
            }
        }
    }
}
