// This class takes care of Translator API calls
//
//

using System;
using System.Net.Http;
using System.Threading.Tasks;
using System.Text;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace TranslatorLibrary
{
    public class Translator
    {
        private static HttpClient ClientTranslator = new HttpClient();
        private const string TranslatorRoute = "/translate?api-version=3.0&to=";

        static public async Task<string> TranslateTextRequest(string subscriptionKey, string endpoint, string inputText, string translationLang)
        {
            object[] body = new object[] { new { Text = inputText } };
            var requestBody = JsonConvert.SerializeObject(body);

            using (HttpRequestMessage requestTranslator = new HttpRequestMessage())
            {
                // Build the request.
                requestTranslator.Method = HttpMethod.Post;
                requestTranslator.RequestUri = new Uri(endpoint + TranslatorRoute + translationLang);
                requestTranslator.Content = new StringContent(requestBody, Encoding.UTF8, "application/json");
                requestTranslator.Headers.Add("Ocp-Apim-Subscription-Key", subscriptionKey);

                // Send the request and get response.
                HttpResponseMessage response = await ClientTranslator.SendAsync(requestTranslator).ConfigureAwait(false);

                if (!response.IsSuccessStatusCode)
                {
                    string message = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    dynamic json = JObject.Parse(message);
                    throw new Exception(response.ReasonPhrase);
                }

                // Read response as a string.
                string result = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                TranslationResult[] deserializedOutput = JsonConvert.DeserializeObject<TranslationResult[]>(result);
                // Iterate over the deserialized results.
                return deserializedOutput[0].Translations.First().Text;
            }
        }
    }
}
