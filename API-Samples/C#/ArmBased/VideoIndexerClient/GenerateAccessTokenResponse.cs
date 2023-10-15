using System.Text.Json.Serialization;

namespace VideoIndexerClient
{
    public class GenerateAccessTokenResponse
    {
        [JsonPropertyName("accessToken")]
        public string AccessToken { get; set; }
    }
}
