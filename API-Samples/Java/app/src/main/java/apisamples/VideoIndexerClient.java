package apisamples;

import apisamples.Account.Account;
import apisamples.HttpUtils.Utils;
import apisamples.authentication.ArmAccessTokenPermission;
import apisamples.authentication.ArmAccessTokenScope;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.text.MessageFormat;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import static apisamples.HttpUtils.Utils.*;
import static java.lang.Thread.sleep;
import static java.util.UUID.randomUUID;

public class VideoIndexerClient {
    public static final String AzureResourceManager = "https://management.azure.com";
    public static final String SubscriptionId = "24237b72-8546-4da5-b204-8c3cb76dd930";
    public static final String ResourceGroup = "ts-poc-wus2-rg";
    public static final String AccountName = "vi-linked-loadtest";
    public static final String ApiVersion = "2022-08-01";
    public static final String ApiUrl = "https://api.videoindexer.ai";
    
    //If you want to be notified with POST events to your website
    //The callback URL can contain additional query parameters for example adding the externalId field
    //Or any Custom Field.
    //Example Callback with custom Parameters : https://webhook.site/#!/0000/?externalId=1234&customField=MyCustomField
    private static final String CallbackUrl = ""; 
    private final Gson gson;
    private Account account = null;
    private TokensStore tokensStore ;


    public VideoIndexerClient(ArmAccessTokenPermission permission, ArmAccessTokenScope scope) {
        gson = new GsonBuilder().setPrettyPrinting().create();
        tokensStore = new TokensStore(permission,scope);
    }

    /**
     * Uploads a video and starts the video index. Calls the uploadVideo API (<a href="https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video">...</a>)
     * 
     * @param videoUrl : the video Url to upload
     * @return Video ID of the video being indexed, otherwise throws exception
     */
    public String uploadVideo(String videoUrl, String videoName) {

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", tokensStore.getVIAccessToken());
        map.put("name", videoName);
        map.put("description", "video_description");
        map.put("privacy", "private");
        map.put("partition", "partition");
        map.put("videoUrl", videoUrl);
        // For API Based Scenarios it is advised to set "NoStream" for faster indexing. 
        map.put("streamingPreset","NoStreaming");
        //Retention Period of Video in days. Default is No retention. Max Allowed value is 7.
        map.put("retentionPeriod","1");
        //Add externalId field in order to eventually  this is useful for external correlation Ids.
        //the field will then be present on the event hub processor.
        map.put("externalId", randomUUID().toString());
        // Use Callback URL to get notified on Video Indexing Events ( Start/ End Processing)
        if (!CallbackUrl.isBlank()) {
            map.put("callbackUrl", URLEncoder.encode(CallbackUrl, StandardCharsets.UTF_8));
        }

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
    public String searchVideo(String videoId) {
        System.out.println(MessageFormat.format("Searching videos in account {0} for video Id {1}.", account.properties.accountId, videoId));

        Map<String, String> map = new HashMap<>();
        map.put("accessToken", tokensStore.getVIAccessToken());
        map.put("id", videoId);
        var queryParam = Utils.toQueryParamString(map);

        try {
            var requestUri = MessageFormat.format("{0}/{1}/Accounts/{2}/Videos/Search?{3}", ApiUrl, account.location, account.properties.accountId,queryParam);
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
            var requestUri = MessageFormat.format("{0}/subscriptions/{1}/resourcegroups/{2}/providers/Microsoft.VideoIndexer/accounts/{3}?api-version={4}",
                    AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
            try {
                HttpRequest request = Utils.httpGetRequestWithBearer(requestUri,tokensStore.getArmAccessToken());
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
        map.put("accessToken", tokensStore.getVIAccessToken());
        //Setting Language is optional, if not set - default language will be used.
        map.put("language", "English");

        var queryParam = Utils.toQueryParamString(map);
        var requestUri = MessageFormat.format("{0}/{1}/Accounts/{2}/Videos/{3}/index?{4}",
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
                            MessageFormat.format("""
                                    The video index has completed. Here is the full JSON of the index for video ID {0}:\s
                                    {1}
                                    """, videoId, response.body()));
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
        map.put("accessToken", tokensStore.getVIAccessToken());
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
