package videoindexersamples;

import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import videoindexersamples.Account.Account;
import videoindexersamples.HttpUtils.Utils;
import videoindexersamples.authentication.AccessTokenRequest;
import videoindexersamples.authentication.AccessTokenResponse;
import videoindexersamples.authentication.ArmAccessTokenPermission;
import videoindexersamples.authentication.ArmAccessTokenScope;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpRequest;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import static java.lang.Thread.sleep;
import static videoindexersamples.HttpUtils.Utils.httpStringResponse;

public class VideoIndexerClient {
    private static final String AzureResourceManager = "https://management.azure.com";
    private static final String SubscriptionId = "<Your_Subscription_Id_here>";
    private static final String ResourceGroup = "<Your_Resource_Group_here>";
    private static final String AccountName = "<Your_Account_Name_Here>";
    private static final String ApiVersion = "2022-08-01";
    private static final String ApiUrl = "https://api.videoindexer.ai";
    private final String armAccessToken;
    private final Gson gson;
    private String accountAccessToken;
    private Account account = null;

    private VideoIndexerClient(String armAccessToken) {
        this.armAccessToken = armAccessToken;
        gson = new GsonBuilder().setPrettyPrinting().create();
    }

    /**
     * Create a new Video Indexer Client.
     * During Creation a DefaultAzureCredential Chain is being invoked .
     *
     * @return the Video Indexer Client
     */
    public static VideoIndexerClient create() {
        var tokenRequestContext = new TokenRequestContext();
        tokenRequestContext.addScopes(String.format("%s/.default", AzureResourceManager));

        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder().build();
        String accessToken = Objects.requireNonNull(defaultCredential.getToken(tokenRequestContext).block()).getToken();
        return new VideoIndexerClient(accessToken);
    }

    /**
     * @param permission - the required permission on the Video Indexer Account
     * @param scope      - The scope of the Access token
     * @param videoId    - the Video ID
     * @param projectId  - the Project ID
     * @return The Video Indexer Account Access Token. Valid for one hour for sequential API Operations
     */
    public VideoIndexerClient getAccountAccessToken(ArmAccessTokenPermission permission, ArmAccessTokenScope scope, String videoId, String projectId) {
        var accessTokenRequest = new AccessTokenRequest(projectId, videoId, permission, scope);
        var accessTokenRequestStr = gson.toJson(accessTokenRequest);

        var requestUri = String.format("%s/subscriptions/%s/resourcegroups/%s/providers/Microsoft.VideoIndexer/accounts/%s/generateAccessToken?api-version=%s", AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI(requestUri))
                    .headers("Content-Type", "application/json;charset=UTF-8")
                    .headers("Authorization", String.format("Bearer %s", this.armAccessToken))
                    .POST(HttpRequest.BodyPublishers.ofString(accessTokenRequestStr))
                    .build();

            var response = httpStringResponse(request);
            AccessTokenResponse accessTokenResponse = gson.fromJson(response.body(), AccessTokenResponse.class);

            this.accountAccessToken = accessTokenResponse.accessToken;
            this.account = getAccount();
            return this;
        } catch (URISyntaxException | IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Uploads a video and starts the video index. Calls the uploadVideo API (<a href="https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video">...</a>)
     * @param videoUrl : the video Url to upload
     * @return Video Id of the video being indexed, otherwise throws exception
     */
    public String uploadVideo(String videoUrl, String videoName) {

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("name", videoName);
        map.put("description", "video_description");
        map.put("privacy", "private");
        map.put("partition", "partition");
        map.put("videoUrl", videoUrl);
        var queryParam = Utils.toQueryParamString(map);

        var requestUri = String.format("%s/%s/Accounts/%s/Videos?%s", ApiUrl, account.location, account.properties.accountId, queryParam);

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI(requestUri))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.noBody())
                    .build();

            var response = httpStringResponse(request);
            Video upoloadedVideo = gson.fromJson(response.body(), Video.class);

            String videoId = upoloadedVideo.id;
            System.out.printf("Video ID %s was uploaded successfully.\n", videoId);
            return videoId;
        } catch (URISyntaxException | IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }


    /**
     * Searches for the video in the account. Calls the searchVideo API (<a href="https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Search-Videos">...</a>)
     * @param videoId The video id
     * @return Video Metadata
     */
    public String getVideo(String videoId) {
        System.out.printf("Searching videos in account %s for video ID %s.\n", account.properties.accountId, videoId);

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("id", videoId);
        var queryParam = Utils.toQueryParamString(map);

        try {
            var requestUri = String.format("%s/%s/Accounts/%s/Videos/Search?%s", ApiUrl, account.location, account.properties.accountId, queryParam);
            return httpStringResponse(Utils.httpGetRequest(requestUri)).body();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    /**
     * Gets an account. Calls the getAccount API (<a href="https://github.com/Azure/azure-rest-api-specs/blob/main/specification/vi/resource-manager/Microsoft.VideoIndexer/stable/2022-08-01/vi.json#:~:text=%22/subscriptions/%7BsubscriptionId%7D/resourceGroups/%7BresourceGroupName%7D/providers/Microsoft.VideoIndexer/accounts/%7BaccountName%7D%22%3A%20%7B">...</a>)
     * @return : The Account Info ( accountId and Location) if successful, otherwise throws an exception</returns>
     */
    public Account getAccount() {
        if (account != null){
            return account;
        }
        System.out.println("Getting Account Data");
        try {
            var requestUri = String.format("%s/subscriptions/%s/resourcegroups/%s/providers/Microsoft.VideoIndexer/accounts/%s?api-version=%s", AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
            try {
                HttpRequest request = HttpRequest.newBuilder().uri(new URI(requestUri))
                        .headers("Content-Type", "application/json;charset=UTF-8")
                        .headers("Authorization", String.format("Bearer %s", this.armAccessToken))
                        .GET()
                        .build();
                var responseBodyJson = httpStringResponse(request).body();
                this.account = gson.fromJson(responseBodyJson, Account.class);
            } catch (URISyntaxException | IOException | InterruptedException e) {
                throw new RuntimeException(e);
            }
            return account;
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    /**
     * Wait for index Operation to finish - pulling method
     *
     * @param videoId - the Id of the video being uploaded
     * @return : true if the wait operation succedded , false otherwise
     */
    public boolean waitForIndex(String videoId) {
        System.out.printf("Waiting for Video %s to finish indexing.\n", videoId);

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("language", "English");
        var queryParam = Utils.toQueryParamString(map);
        var requestUri = String.format("%s/%s/Accounts/%s/Videos/%s/index?%s", ApiUrl, account.location, account.properties.accountId, videoId, queryParam);
        while (true) { //
            try {

                var request = Utils.httpGetRequest(requestUri);
                var response = httpStringResponse(request);
                Video prorcessedVideo = gson.fromJson(response.body(), Video.class);
                String processingState = prorcessedVideo.state;

                // If job is finished
                if (Objects.equals(processingState, ProcessingState.Processed.toString())) {
                    System.out.printf("The video index has completed. Here is the full JSON of the index for video ID %s: \n%s\n", videoId, response.body());
                    return true;
                } else if (Objects.equals(processingState, ProcessingState.Failed.toString())) {
                    System.out.printf("The video index failed for video ID %s.\n", videoId);
                    return false;
                }
                // Job hasn't finished
                System.out.printf("The video index state is %s\n", processingState);
                sleep(10000);
            } catch (URISyntaxException | IOException | InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }
}
