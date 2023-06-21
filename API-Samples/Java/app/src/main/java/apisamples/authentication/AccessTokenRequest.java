package apisamples.authentication;


/**
 * The request model for getting Video Indexer Access Token
 */
public class AccessTokenRequest {
    public ArmAccessTokenPermission permissionType;
    public ArmAccessTokenScope scope;

    public String videoId;
    public String projectId;


    public AccessTokenRequest(ArmAccessTokenPermission permission, ArmAccessTokenScope scope) {
        this.permissionType = permission;
        this.scope = scope;
        //we assume Project ID and Video ID Based Scoped  are not used in this sample, hence will be set to null
        this.videoId = null;
        this.projectId = null;

    }

}

