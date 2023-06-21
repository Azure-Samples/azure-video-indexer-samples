package apisamples;

import apisamples.Account.Account;
import apisamples.authentication.ArmAccessTokenPermission;
import apisamples.authentication.ArmAccessTokenScope;

public class App {

    private static final String VideoUrl = "<Place_Your_Video_URL_HERE>";

    public static void main(String[] args) {

        System.out.println("Video Indexer API Samples");
        System.out.println("==========================");

        //1. Create a VideoIndexerClient which encapsulates Http calls and AccessTokens
        //The Video Indexer Client stores the credentials in TokensStore based on the permission asked for this VideoIndexerClient (Contributor on the account level)
        System.out.println("Creating Video Indexer Client Instance");
        var videoIndexerClient = new VideoIndexerClient(ArmAccessTokenPermission.Contributor, ArmAccessTokenScope.Account);

        //3. Get Account Information
        Account account = videoIndexerClient.getAccountInfo();
        System.out.printf("The account ID is %s\n", account.properties.accountId);
        System.out.printf("The account Location is %s\n", account.location);

        //4. Upload Video
        System.out.println("Uploading Video from publicly accessed URI");
        var videoId = videoIndexerClient.uploadVideo(VideoUrl, "video-345-sample");
        System.out.printf("Successfully uploaded video with Id: %s\n", videoId);

        // 5 . Wait For Completion
        // In Production use  more sophisticated Async/Await with CompletableFuture/Mono /etc.
        System.out.println("Waiting For index To Complete");
        var waitResult = videoIndexerClient.waitForIndex(videoId);
        System.out.println("wait result  = " + waitResult);

        //6. Search Video
        var videoMetadata = videoIndexerClient.searchVideo(videoId);
        System.out.printf("Video Metadata : \n%s\n", videoMetadata);

        //7. Delete Video : marked out as we chose to use retention parameter
        // The video and all related media assets wil be removed after 1 day.
        // You can still look at videoIndexerClient.deleteVideo to see how the delete API works

        //  System.out.printf("Deleting Video %s.\n", videoId);
        //  videoIndexerClient.deleteVideo(videoId);
    }

}
