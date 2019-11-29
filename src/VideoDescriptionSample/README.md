# Video Description Sample

This sample application displays an automatic description of Video Indexer thumbnails. The web app grabs the thumbnails from a video stored in Microsoft Video Indexer, calls Computer Vision to get a description and translates it to another language.

# Azure resources needed 
Before running the app, you need to have or create :
- a trial or production Video Indexer Account. Susbcribe to get the VI API Key from this [site](https://api-portal.videoindexer.ai/) (please connect using the option at top right). To get the key, please read this [article] (https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis#subscribe-to-the-api)
- an Azure Storage Account (the app will use it to copy the thumnails from Video Indexer and will generate a lower version too)
- a Computer Vision resource. Follow this [article](https://docs.microsoft.com/en-us/azure/cognitive-services/computer-vision/tutorials/storage-lab-tutorial#create-a-computer-vision-resource)
- optional : a Translator resource. Follow this [article](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/translator-text-how-to-signup)

# App configuation
Once the resources are created, you need to define the following entries in Web.config file:

    <add key="StorageConnectionString" value="DefaultEndpointsProtocol=https;AccountName=yourstorageaccountname;AccountKey=yourstorageaccountkey;EndpointSuffix=core.windows.net" />
    <add key="VisionSubscriptionKey" value="insertyourkeyhere" />
    <add key="VisionEndpoint" value="https://yourvisionaccount.cognitiveservices.azure.com/" />
    <add key="TranslatorSubscriptionKey" value="insertyourkeyhere" />
    <add key="TranslatorEndpoint" value="https://api-eur.cognitive.microsofttranslator.com" />
    <add key="VideoIndexerAccountId" value="insertyourkeyhere" />
    <add key="VideoIndexerLocation" value="Trial" />
    <add key="VideoIndexerSubscriptionKey" value="insertyourkeyhere" />
    <add key="TranslationLang" value="fr" />


## Running the web app on a video
You can run the web app, connect to Video Indexer and process the thumbnails by specifying the video Id.

To identify the video Id of your video, look to the URL in Video Indexer. Url will look like [https://www.videoindexer.ai/accounts/ad6cf452-26e0-46e3-b8fa-4551624f4532/videos/**bf2669d99d**/?location=Trial](https://www.videoindexer.ai/accounts/ad6cf452-26e0-46e3-b8fa-4551624f4532/videos/bf2669d99d/?location=Trial) in that case the Video is **bf2669d99d**

## Notes
Known issues
* When processing a video, the progress bar based on SignalR is seen by all users accessing the site