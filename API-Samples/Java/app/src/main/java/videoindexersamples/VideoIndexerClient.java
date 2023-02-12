package videoindexersamples;

import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import videoindexersamples.Account.Account;
import videoindexersamples.authentication.AccessTokenRequest;
import videoindexersamples.authentication.AccessTokenResponse;
import videoindexersamples.authentication.ArmAccessTokenPermission;
import videoindexersamples.authentication.ArmAccessTokenScope;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class VideoIndexerClient {
    private static final String AzureResourceManager = "https://management.azure.com";
    private static final String SubscriptionId = "24237b72-8546-4da5-b204-8c3cb76dd930";
    private static final String ResourceGroup = "einav-weu-rg";
    private static final String AccountName = "einav-sea-vi";
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

    static String urlEncodeUTF8(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    /**
     * @param permission - the required permission on the Video Indexer Account
     * @param scope      - The scope of the Access token
     * @param videoId    - the Video ID
     * @param projectId  - the Project ID
     * @return The Video Indexer Account Access Token. Valid for one hour for sequential API Operations
     */
    public String getAccountAccessToken(ArmAccessTokenPermission permission, ArmAccessTokenScope scope, String videoId, String projectId) {
        var accessTokenRequest = new AccessTokenRequest(projectId, videoId, permission, scope);
        var accessTokenRequestStr = gson.toJson(accessTokenRequest);
        System.out.println("Requesting Account Access Token: " + accessTokenRequestStr);

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
            System.out.println(this.accountAccessToken);
            return this.accountAccessToken;
        } catch (URISyntaxException | IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Upload a Viode to the Video Indexer Account and Start indexing it.
     *
     * @param videoUrl : the video Url to upload
     * @return the Video Upload Status
     */
    public String uploadVideo(String videoUrl) {
        System.out.println(this.accountAccessToken);
        Map<String, String> map = new HashMap<>();
        map.put("accessToken", this.accountAccessToken);
        map.put("name", "JavaVideoSample");
        map.put("description", "VideoDescription");
        map.put("privacy", "private");
        map.put("partition", "partition");
        map.put("videoUrl", videoUrl);

        var queryParam = map.entrySet().stream()
                .map(p -> urlEncodeUTF8(p.getKey()) + "=" + urlEncodeUTF8(p.getValue()))
                .reduce((p1, p2) -> p1 + "&" + p2).orElse("");

        var requestUri = String.format("%s/%s/Accounts/%s/Videos?%s", ApiUrl, account.location, account.properties.accountId, queryParam);
        System.out.printf("%s", requestUri);

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI(requestUri))
                    .headers("Content-Type", "multipart/form-data;charset=UTF-8")
                    .headers("Authorization", String.format("Bearer %s", this.armAccessToken))
                    .POST(HttpRequest.BodyPublishers.noBody()).build();

            HttpResponse<String> response = HttpClient.newBuilder()
                    .build()
                    .send(request, HttpResponse.BodyHandlers.ofString());

            System.out.println(response.body());
            return response.body();
        } catch (URISyntaxException | IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Get Account info
     * @return : The Account Info ( accountId and Location)
     */
    public Account getAccount() {
        System.out.println("Getting Account Data");
        try {
            var requestUri = String.format("%s/subscriptions/%s/resourcegroups/%s/providers/Microsoft.VideoIndexer/accounts/%s?api-version=%s", AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
            try {
                HttpRequest request = HttpRequest.newBuilder().uri(new URI(requestUri)).headers("Content-Type", "application/json;charset=UTF-8").headers("Authorization", String.format("Bearer %s", this.armAccessToken)).GET().build();

                HttpResponse<String> response = HttpClient.newBuilder().build().send(request, HttpResponse.BodyHandlers.ofString());
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
}
