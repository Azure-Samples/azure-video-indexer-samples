(function(){
  
      // Init Source
      function initSource() {
        
        // Paste the streaming endpoint and the viewToken. you can find them at GetVideoIndex response
        // (https://api-portal.videoindexer.ai/docs/services/operations/operations/Get-Video-Index)
          myPlayer.src([
                      {
                  // get the src (streaming endpoint) from GetVideoIndex.videos[0].publishedUrl
                  "src": "https://rodmandev.streaming.mediaservices.windows.net/0e1a5e64-3552-46e1-a775-74ef187ecb1d/Video_Indexer_FinalCut.ism/manifest",
                  "type": "video/mp4",
                  "protectionInfo": [{
                      type: "AES",
                      // Get the authenticationToken from GetVideoIndex.videos[0].viewToken
                    //  authenticationToken:
                  }]
              }
          ], []);
      }

      // Init your AMP instance
      let myPlayer = amp('vid1', { /* Options */
          "nativeControlsForTouch": false,
          autoplay: true,
          controls: true,
          width: "640",
          height: "360",
          poster: ""
      }, function () {


          // Set the source dynamically
          initSource.call(this);
      });

      myPlayer.addEventListener("pause", function(event){
        console.log("paused");
      });
}())
