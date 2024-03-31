(function(){
  
  // Init
  var viPlayerIframe = document.getElementById("viPlayer");
  var button = document.getElementById("myButton");
  var input = document.getElementById("time");

  var playButton = document.getElementById("playButton");
  var pauseButton = document.getElementById("pauseButton");
  
  var playerStatus = document.getElementById("playerStatus");
  
  // Define event listeners
  button.addEventListener("click", function(){
    var time = parseFloat(input.value);
    notifyPlayer({
      time: time
    });
  });

  playButton.addEventListener("click", function(){
    notifyPlayer({
      play: true
    });
  });

  pauseButton.addEventListener("click", function(){
    notifyPlayer({
      pause: true
    });
  });
  
  window.addEventListener("message", function(e){
    if (e?.data?.loaded) {
      playerStatus.value = "Player loaded";
    } else if (e?.data?.played) {
      playerStatus.value = "Playing";
    } else if (e?.data?.paused) {
      playerStatus.value = "Paused";
    }
  });

  // Send message to other iframe.
  function notifyPlayer(data) {
    let payload = {
        ...data,
        origin: "https://www.videoindexer.ai"
    };
    
    if ('postMessage' in window) {
      try {
          viPlayerIframe.contentWindow.postMessage(payload, payload.origin);
      } catch (error) {
        throw error;
      }
    }
  }
  
}())