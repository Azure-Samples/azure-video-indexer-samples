package apisamples;

import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import apisamples.Account.Account;
import apisamples.HttpUtils.Utils;
import apisamples.authentication.AccessTokenRequest;
import apisamples.authentication.AccessTokenResponse;
import apisamples.authentication.ArmAccessTokenPermission;
import apisamples.authentication.ArmAccessTokenScope;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.text.MessageFormat;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import static java.lang.Thread.sleep;
import static apisamples.HttpUtils.Utils.*;

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
     */
    public void getAccountAccessToken(ArmAccessTokenPermission permission, ArmAccessTokenScope scope, String videoId, String projectId) {
        var accessTokenRequest = new AccessTokenRequest(projectId, videoId, permission, scope);
        var accessTokenRequestStr = gson.toJson(accessTokenRequest);

        var requestUri = MessageFormat.format("{0}/subscriptions/{1}/resourcegroups/{2}/providers/Microsoft.VideoIndexer/accounts/{3}/generateAccessToken?api-version={4}",
                                              AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI(requestUri))
                    .headers("Content-Type", "application/json;charset=UTF-8")
                    .headers("Authorization", "Bearer " + this.armAccessToken)
                    .POST(HttpRequest.BodyPublishers.ofString(accessTokenRequestStr))
                    .build();

            var response = httpStringResponse(request);
            AccessTokenResponse accessTokenResponse = gson.fromJson(response.body(), AccessTokenResponse.class);
            this.accountAccessToken = accessTokenResponse.accessToken;
        } catch (URISyntaxException | IOException | InterruptedException ex) {
            throw new RuntimeException(ex);
        }
    }

    /**
     * Uploads a video and starts the video index. Calls the uploadVideo API (<a href="https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video">...</a>)
     *
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
        map.put("streamingPreset","NoStreaming");
        var queryParam = Utils.toQueryParamString(map);

        var requestUri = MessageFormat.format("{0}/{1}/Accounts/{2}/Videos?{3}", ApiUrl, account.location, account.properties.accountId, queryParam);

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI(requestUri))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.noBody())
                    .build();

            var response = httpStringResponse(request);
            Video upoloadedVideo = gson.fromJson(response.body(), Video.class);

            String videoId = upoloadedVideo.id;
            System.out.println(MessageFormat.format("Video ID {0} was uploaded successfully", videoId));
            return videoId;
        } catch (URISyntaxException | IOException | InterruptedException ex) {
            throw new RuntimeException(ex);
        }
    }


    /**
     * Searches for the video in the account. Calls the searchVideo API (<a href="https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Search-Videos">...</a>)
     *
     * @param videoId The video id
     * @return Video Metadata
     */
    public String getVideo(String videoId) {
        System.out.println(MessageFormat.format("Searching videos in account {0} for video Id {1}.", account.properties.accountId, videoId));

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("id", videoId);
        var queryParam = Utils.toQueryParamString(map);

        try {
            var requestUri = MessageFormat.format("{0}/{1}/Accounts/{2}/Videos/Search?{3}", ApiUrl, account.location, account.properties.accountId, queryParam);
            var httpRequest = Utils.httpGetRequest(requestUri);
            var httpResponse = Utils.httpStringResponse(httpRequest);
            return httpResponse.body();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    /**
     * Gets an account. Calls the getAccount API (<a href="https://github.com/Azure/azure-rest-api-specs/blob/main/specification/vi/resource-manager/Microsoft.VideoIndexer/stable/2022-08-01/vi.json#:~:text=%22/subscriptions/%7BsubscriptionId%7D/resourceGroups/%7BresourceGroupName%7D/providers/Microsoft.VideoIndexer/accounts/%7BaccountName%7D%22%3A%20%7B">...</a>)
     *
     * @return : The Account Info ( accountId and Location) if successful, otherwise throws an exception</returns>
     */
    public Account getAccountInfo() {
        System.out.println("Getting Account Info ( Location/AccountId)");
        try {
            var requestUri = MessageFormat.format("%{0}/subscriptions/%{1}/resourcegroups/%{2}/providers/Microsoft.VideoIndexer/accounts/{3}?api-version={4}",
                    AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
            try {
                HttpRequest request = httpGetRequest(requestUri);
                var responseBodyJson = httpStringResponse(request).body();
                this.account = gson.fromJson(responseBodyJson, Account.class);
            } catch (URISyntaxException | IOException | InterruptedException ex) {
                throw new RuntimeException(ex);
            }
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
        return this.account;
    }

    /**
     * Calls getVideoIndex API in 10 second intervals until the indexing state is 'processed'(<a href="https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Index">...</a>)
     *
     * @param videoId - the Id of the video being uploaded
     * @return : true if the wait operation succedded , false otherwise
     */
    public boolean waitForIndex(String videoId) {
        System.out.printf("Waiting for Video %s to finish indexing.\n", videoId);

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        //Setting Language is optional, if not set - default language will be used.
        map.put("language", "English");

        var queryParam = Utils.toQueryParamString(map);
        var requestUri = MessageFormat.format("{0}/{1}/Accounts/{1}/Videos/{3}/index?{4}",
                ApiUrl, account.location, account.properties.accountId, videoId, queryParam);

        // Sample Polling to retrieve completion.
        // Refer to the VideoIndexerEventProcessor class to use event Hubs processing of Video Indexer events.
        while (true) {
            try {

                var request = Utils.httpGetRequest(requestUri);
                var response = httpStringResponse(request);
                Video prorcessedVideo = gson.fromJson(response.body(), Video.class);
                String processingState = prorcessedVideo.state;

                // If job is finished
                if (Objects.equals(processingState, ProcessingState.Processed.toString())) {
                    System.out.println(
                            MessageFormat.format("The video index has completed. " +
                                    "Here is the full JSON of the index for video ID {0}: \n{1}\n", videoId, response.body()));
                    return true;
                } else if (Objects.equals(processingState, ProcessingState.Failed.toString())) {
                    System.out.println(MessageFormat.format("The video index failed for video Id {0}", videoId));
                    return false;
                }
                // Job hasn't finished
                System.out.println(MessageFormat.format("The video index state is {0}", processingState));
                sleep(10000);
            } catch (URISyntaxException | IOException | InterruptedException ex) {
                throw new RuntimeException(ex);
            }
        }
    }

    /**
     * Deletes the specified video and all related insights created from when the video was indexed
     *
     * @param videoId The Video Id
     */
    public void deleteVideo(String videoId) {

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        var queryParam = Utils.toQueryParamString(map);
        var requestUri = MessageFormat.format("{0}/{1}/Accounts/{2}/Videos/{3}?{4}",
                ApiUrl, account.location, account.properties.accountId, videoId, queryParam);

        try {
            var httpRequest = HttpRequest.newBuilder()
                    .uri(new URI(requestUri))
                    .headers("Content-Type", "application/json;charset=UTF-8")
                    .DELETE()
                    .build();
            var response = HttpClient
                    .newBuilder()
                    .build()
                    .send(httpRequest, HttpResponse.BodyHandlers.discarding());
            VerifyStatus(response, NO_CONTENT);

        } catch (URISyntaxException | IOException | InterruptedException ex) {
            throw new RuntimeException(ex);
        }
    }
}
