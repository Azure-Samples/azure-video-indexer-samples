(function(){
  
  // Init
  var viPlayerIframe = document.getElementById("viPlayer");
  var button = document.getElementById("myButton");
  var input = document.getElementById("time");
  
  // Define event listeners
  button.addEventListener("click", function(){
    var time = parseFloat(input.value);
    notifyPlayer(time);
  });
  
  // Send message to other iframe.
  function notifyPlayer(time) {
    let payload = {
        time: time, 
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