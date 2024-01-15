using System.Text.Json.Serialization;
namespace VideoIndexerClient.model;
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.

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

