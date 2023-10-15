using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient.auth
{
    public class GenerateAccessTokenResponse
    {
        [JsonPropertyName("accessToken")]
        public string AccessToken { get; set; }
    }
}
