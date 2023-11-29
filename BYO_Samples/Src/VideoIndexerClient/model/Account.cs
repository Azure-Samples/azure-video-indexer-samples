using System.Text.Json.Serialization;

namespace VideoIndexerClient.model;

public class Account
{
    [JsonPropertyName("properties")]
    public AccountProperties Properties { get; set; }

    [JsonPropertyName("location")]
    public string Location { get; set; }
}

public class AccountProperties
{
    [JsonPropertyName("accountId")]
    public string Id { get; set; }
}

