package videoindexersamples;

import videoindexersamples.Account.Account;
import videoindexersamples.authentication.ArmAccessTokenPermission;
import videoindexersamples.authentication.ArmAccessTokenScope;

public class App {

    private static final String VideoUrl = "";

    public static void main(String[] args) {

        System.out.println("Video Indexer API Samples");
        System.out.println("==========================");

        //1. Create a VideoIndexerClient which encapsulates Http calls and AccessTokens
        System.out.println("Creating Video Indexer Client Instance");
        var videoIndexerClient = VideoIndexerClient.create();


        //2. Explicit Get Account Access Token
        // You can use the account Access Token for subsequent requests , in this demo it is stored inside the VideoIndexer Client.
        // The Token is valid for 1 hour
        System.out.println("Get Account Access Token");
        videoIndexerClient.getAccountAccessToken(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Account, null, null);

        //3. Get Account Information
        Account account = videoIndexerClient.getAccount();
        System.out.printf("The account ID is %s\n", account.properties.accountId);
        System.out.printf("The account Location is %s\n", account.location);

        //4. Upload Video
        var videoId = videoIndexerClient.uploadVideo(VideoUrl, "video-345-sample");
        System.out.printf("Successfully uploaded video with Id: %s\n", videoId);

        // 5 . Wait For Completion
        // In Production use  more sophisticated Async/Await with CompletableFuture/Mono /etc.
        System.out.println("Waiting For index To Complete");
        var waitResult = videoIndexerClient.waitForIndex(videoId);
        System.out.println("wait result  = " + waitResult);

        //6. Get Index Insights
        var videoMetadata = videoIndexerClient.getVideo(videoId);
        System.out.printf("Video Metadata : \n%s\n", videoMetadata);
    }

}
