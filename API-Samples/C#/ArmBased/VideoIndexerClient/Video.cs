using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient;

public class Video
{
    [JsonPropertyName("id")]
    public string Id { get; set; }

    [JsonPropertyName("state")]
    public string State { get; set; }
}