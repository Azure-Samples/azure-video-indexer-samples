using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient;

public class AccountProperties
{
    [JsonPropertyName("accountId")]
    public string Id { get; set; }
}