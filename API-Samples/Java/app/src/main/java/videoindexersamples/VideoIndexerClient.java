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
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class VideoIndexerClient {
    private static final String AzureResourceManager = "https://management.azure.com";
    private static final String SubscriptionId = "24237b72-8546-4da5-b204-8c3cb76dd930";
    private static final String ResourceGroup = "arm-demo-rg";
    private static final String AccountName = "arm-demo-account";
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
    public static VideoIndexerClient build() {
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
    public boolean getAccountAccessToken(ArmAccessTokenPermission permission, ArmAccessTokenScope scope, String videoId, String projectId) {
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

            HttpResponse<String> response = HttpClient
                    .newBuilder()
                    .build()
                    .send(request, HttpResponse.BodyHandlers.ofString());

            AccessTokenResponse accessTokenResponse = gson.fromJson(response.body(), AccessTokenResponse.class);
            this.accountAccessToken = accessTokenResponse.accessToken;
            return true;
        } catch (URISyntaxException | IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Upload a Viode to the Video Indexer Account and Start indexing it.
     *
     * @param videoUrl : the video Url to upload
     * @return the Video Id
     */
    public String uploadVideo(String videoUrl) {

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("name", "part2-video");
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

            HttpResponse<String> response = HttpClient.newBuilder()
                    .build()
                    .send(request, HttpResponse.BodyHandlers.ofString());

            Video upoloadedVideo = gson.fromJson(response.body(), Video.class);
            String videoId = upoloadedVideo.id;
            System.out.printf("Video ID %s was uploaded successfully.\n", videoId);
            return videoId;
        } catch (URISyntaxException | IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Get Account info - Retreive the account info such as Account Id and Location
     *
     * @return : The Account Info ( accountId and Location)
     */
    public Account getAccount() {
        System.out.println("Getting Account Data");
        try {
            var requestUri = String.format("%s/subscriptions/%s/resourcegroups/%s/providers/Microsoft.VideoIndexer/accounts/%s?api-version=%s", AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
            try {
                HttpRequest request = HttpRequest.newBuilder().uri(new URI(requestUri))
                        .headers("Content-Type", "application/json;charset=UTF-8")
                        .headers("Authorization", String.format("Bearer %s", this.armAccessToken))
                        .GET()
                        .build();

                HttpResponse<String> response = HttpClient.
                        newBuilder().
                        build().
                        send(request, HttpResponse.BodyHandlers.ofString());

                var responseBodyJson = response.body();
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
     *  Wait for index Operation to finish - pulling method
     * @param videoId - the Id of the video being uploaded
     * @return : true if the wait operation succedded , false otherwise
     */
    public boolean waitForIndex(String videoId) {
        System.out.printf("Waiting for Video %s to finish indexing.\n", videoId);

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("language", "English");
        var queryParam = Utils.toQueryParamString(map);
        int count = 0;
        while (count < 360) {
            var requestUri = String.format("%s/%s/Accounts/%s/Videos/%s/index?%s", ApiUrl, account.location, account.properties.accountId, videoId, queryParam);

            HttpRequest request = null;
            try {
                request = HttpRequest.newBuilder()
                        .uri(new URI(requestUri))
                        .headers("Content-Type", "application/json;charset=UTF-8")
                        .GET()
                        .build();

            HttpResponse<String> response = HttpClient.
                    newBuilder().
                    build().
                    send(request, HttpResponse.BodyHandlers.ofString());

            String processingState = gson.fromJson(response.body(), Video.class).state;
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
            Thread.sleep(10000);
            count++;
            } catch (URISyntaxException | IOException | InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
        return false;
    }
}
