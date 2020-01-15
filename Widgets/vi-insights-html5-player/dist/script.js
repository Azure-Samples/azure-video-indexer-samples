(function(){
    // Reference your player instance
    var playerInstance = document.getElementById('vid1');
     var viPlayerIframe = document.getElementById("viInsights");

    function jumpTo(evt) {
      var origin = evt.origin || evt.originalEvent.origin;

      // Validate that event comes from video indexer domain.
      if ((origin === "https://www.videoindexer.ai") && evt.data){
        
        if(evt.data.time !== undefined) {
            // Here you need to call your player "jumpTo" implementation
            
            playerInstance.currentTime = evt.data.time;   
        }
        
        if(evt.data.language !== undefined) {
            // Here you will need to call your "change language" implementation
            playerInstance.language = evt.data.language;
        }
        
       
        // Confirm arrival to us
        if ('postMessage' in window) {
          evt.source.postMessage({confirm: true, time: evt.data.time}, origin);
        }
      }
    }

    // Listen to message event
    window.addEventListener("message", jumpTo, false);
  
    // Notify VI 
    playerInstance.addEventListener("timeupdate", function(){
      let payload = {
        currentTime: this.currentTime, 
        origin: "https://www.videoindexer.ai"
      };
      if ('postMessage' in window) {
        try {
            viPlayerIframe.contentWindow.postMessage(payload, payload.origin);
        } catch (error) {
          throw error;
        }
      }
    })
  
}())  