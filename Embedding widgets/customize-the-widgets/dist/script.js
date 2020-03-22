$(()=> {
  const button = $('button');
  const insightsIframe = $('#insightsIframe');
  button.on('click', ()=> {
    insightsIframe.toggle();
  });
});
// We're rendering only the people and search by specifying &widgets=.....
// See all available options at https://docs.microsoft.com/en-us/azure/cognitive-services/video-indexer/video-indexer-embed-widgets 

// examples: 
// https://www.videoindexer.ai/embed/insights/00000000-0000-0000-0000-000000000000/4dc0aa32bf/?widgets=transcript&tab=timeline