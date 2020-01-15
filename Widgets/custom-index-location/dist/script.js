// This snippet is incharge of the form at the left side.
$(()=>{
  // Save DOM references.
  const iframe = $('iframe#insights');
  const iframeSrc = iframe.attr('src');
  const indexInput = $('input');
  const imagesLocation = $('#imagesLocation');
  const iframeUrlInput = $('#iframeUrl');

  // Update the iframe embed url from the form inputs.
  $('#loadBtn').click(()=> {
    const url = `${iframeSrc}?customIndexLocation=${encodeURIComponent(indexInput.val())}&customImagesLocation=${encodeURIComponent(imagesLocation.val())}`;
    iframe.attr('src', url);
    iframeUrlInput.val(url);
  });
});


// this peace of code is incharge of the communication between the 2 widgets.
(function () {
    'use strict';

        // Jump to specific time from mesage payload
        function notifyWidgets(evt) {

            if (!evt) {
                return;
            }
            var origin = evt.origin || evt.originalEvent.origin;

            // Validate that event comes from an approved domain. (change to your host domain)
            if ((origin === "https://www.videoindexer.ai") && (evt.data.time !== undefined || evt.data.currentTime !== undefined || evt.data.language !== undefined)) {

                // Pass message to other iframe.
                if ('postMessage' in window) {
                    var iframes = window.document.getElementsByTagName('iframe');
                    try {
                        for (var index = 0; index < iframes.length; index++) {
                            iframes[index].contentWindow.postMessage(evt.data, origin);
                        }
                    } catch (error) {
                        throw error;
                    }
                }
            }
        }

        function clearMessageEvent() {
            if (window.removeEventListener) {                   // For all major browsers, ewindowcept IE 8 and earlier
                window.removeEventListener("message");
            } else if (window.detachEvent) {                    // For IE 8 and earlier versions
                window.detachEvent("message");
            }
        }

        // Listen to message events from breakdown iframes
        window.addEventListener("message", notifyWidgets, false);

        // Clear the event if window unloads
        window.onunload = clearMessageEvent;

}());