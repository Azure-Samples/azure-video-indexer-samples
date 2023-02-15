package videoindexersamples.authentication;


/**
 * The request model for getting Video Indexer Access Token
 */
public class AccessTokenRequest {
    public String videoId;
    public String projectId;
    public ArmAccessTokenPermission permissionType;
    public ArmAccessTokenScope scope;

    public AccessTokenRequest(String videoId, String projectId, ArmAccessTokenPermission permission, ArmAccessTokenScope scope) {
        this.videoId = videoId;
        this.projectId = projectId;
        this.permissionType = permission;
        this.scope = scope;
    }


}

