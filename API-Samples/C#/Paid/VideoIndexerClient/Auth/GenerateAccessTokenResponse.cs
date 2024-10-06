using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient.Auth
{
    public class GenerateAccessTokenResponse
    {
        [JsonPropertyName("accessToken")]
        public string AccessToken { get; set; }
    }
}
