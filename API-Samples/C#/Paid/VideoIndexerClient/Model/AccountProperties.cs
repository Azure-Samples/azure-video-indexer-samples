using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient.Model;

public class AccountProperties
{
    [JsonPropertyName("accountId")]
    public string Id { get; set; }
}