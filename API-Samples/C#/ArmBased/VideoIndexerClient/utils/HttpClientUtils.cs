using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace VideoIndexingARMAccounts.VideoIndexerClient.utils
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
