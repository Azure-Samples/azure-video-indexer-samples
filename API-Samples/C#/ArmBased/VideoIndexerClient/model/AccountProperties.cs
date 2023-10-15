using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient.model;

public class AccountProperties
{
    [JsonPropertyName("accountId")]
    public string Id { get; set; }
}