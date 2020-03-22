(function() {
    // Init Source
    function initSource() {
      let tracks = [
        {
          kind: "captions",
          // Here is how to load vtt from VI, you can replace it with your vtt url.
          src: this.getSubtitlesUrl("en-US"),
          label: "English"
        }
      ];

      // Paste the streaming endpoint and the viewToken. you can find them at GetVideoStreaming response
      // (https://api-portal.videoindexer.ai/docs/services/Operations/operations/Get-Video-Streaming-URL)
      myPlayer.src(
        [
          {
            // get the src (streaming endpoint) from GetVideoIndex.videos[0].publishedUrl
            src:
              "https://rodmandev.streaming.mediaservices.windows.net/b36bbdad-c001-4f87-84ac-88a67359c13f/What%20is%20Office.ism/manifest(encryption=cbc,format=mpd-time-csf)",
            type: "video/mp4",
            protectionInfo: [
              {
                type: "AES",
                // Get the authenticationToken from GetVideoIndex.videos[0].viewToken
                authenticationToken:
                  "Bearer=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1cm46bWljcm9zb2Z0OmF6dXJlOm1lZGlhc2VydmljZXM6Y29udGVudGtleWlkZW50aWZpZXIiOiJmYTQ1ZjdlZC02YTNjLTQyMTMtYmQwYi1iMDg3NjA5NWVjZGIiLCJpc3MiOiJodHRwczovL2JyZWFrZG93bi5tZSIsImF1ZCI6IkJyZWFrZG93blVzZXIiLCJleHAiOjE1NzY4NDExODcsIm5iZiI6MTU3NDI0OTEyN30.RA9ptDoQO6NM8_psB2EnAXzWRYcF5zloHPYmtKqskt4"
              }
            ]
          }
        ],
        []
      );
    }

    // Init your AMP instance
    let myPlayer = amp(
      "vid1",
      {
        /* Options */
        nativeControlsForTouch: false,
        autoplay: true,
        controls: true,
        width: "640",
        height: "400",
        poster: "",
        plugins: {
          // Declare the vi plugin
          videobreakedown: {}
        }
      },
      function() {
        // Init the plugin
        this.videobreakdown({
          videoId: "9a296c6ec3",
          accountId: "00000000-0000-0000-0000-000000000000",
          syncTranscript: true,
          syncLanguage: true,
          accessToken: "" // pass accessToken if you embed a private video only
          // (https://api-portal.videoindexer.ai/docs/services/authorization/operations/Get-Video-Access-Token?)
        });

        // Set the source dynamically
        initSource.call(this);
      }
    );

    myPlayer.addEventListener("pause", function(event) {
      console.log("paused");
    });
  })();