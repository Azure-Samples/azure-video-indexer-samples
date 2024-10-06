using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient.Auth
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum ArmAccessTokenPermission
    {
        Reader,
        Contributor,
        MyAccessAdministrator,
        Owner,
    }
}
