using System.Text.Json.Serialization;

namespace VideoIndexingARMAccounts.VideoIndexerClient.auth
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
