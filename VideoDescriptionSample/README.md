# Video Description Sample

This sample application displays an automatic description of Video Indexer thumbnails. The web app grabs the thumbnails from a video stored in Microsoft Video Indexer, calls Computer Vision to get a description and translates it to another language.

Screen capture :

![Screen capture 1](images/vd-img1.png?raw=true)
![Screen capture 2](images/vd-img2.png?raw=true)

## Azure resources needed 
Before running the app, you need to have or create :
- a trial or production Video Indexer Account. Susbcribe to get the VI API Key from this [site](https://api-portal.videoindexer.ai/) (please connect using the option at top right). To get the key, please read this [article] (https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis#subscribe-to-the-api)
- an Azure Storage Account (the app will use it to copy the thumnails from Video Indexer and will generate a lower version too)
- a Computer Vision resource. Follow this [article](https://docs.microsoft.com/en-us/azure/cognitive-services/computer-vision/tutorials/storage-lab-tutorial#create-a-computer-vision-resource)
- optional : a Translator resource. Follow this [article](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/translator-text-how-to-signup)

## App configuration
Let's see how to configure all these services in you Web.config file:

### Video Indexer 
You'll need to configure the following 3 lines:

    <add key="VideoIndexerAccountId" value="insertyouraccountidhere" />
    <add key="VideoIndexerLocation" value="Trial" />
    <add key="VideoIndexerSubscriptionKey" value="insertyourkeyhere" />

**VideoIndexerAccountId**

If you already have a Video Indexer account, you can get your account ID from the [Settings page](https://www.videoindexer.ai/settings/account)

![AccountId](https://docs.microsoft.com/en-us/azure/media-services/video-indexer/media/video-indexer-use-apis/account-id.png)

**VideoIndexerLocation**

Leave as Trial (unless your account is not trial)

**VideoIndexerSubscriptionKey**

Susbcribe to get the VI API Key from this [site](https://api-portal.videoindexer.ai/) (please connect using the option at top right). To get the key, please read this [article](https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis#subscribe-to-the-api)

Copy the Primary key by hitting "Show" as image below

![Image](https://docs.microsoft.com/en-us/azure/media-services/video-indexer/media/video-indexer-use-apis/video-indexer-api03.png)


### Azure Storage
This storage account will be used to it to copy the thumbnails from Video Indexer and will generate a lower version.
You'll need to configure:

	<add key="StorageConnectionString" value="DefaultEndpointsProtocol=https;AccountName=yourstorageaccountname;AccountKey=yourstorageaccountkey;EndpointSuffix=core.windows.net" />

**AccountName** and **AccountKey**
Check [this article](https://docs.microsoft.com/en-us/azure/storage/common/storage-configure-connection-string) on how to get the account name and account key:
![Account Name](https://docs.microsoft.com/en-us/azure/includes/media/storage-view-keys-include/portal-connection-string.png)


### Computer Vision
You'll need to configure the following 2 lines:

    <add key="VisionSubscriptionKey" value="insertyourkeyhere" />
    <add key="VisionEndpoint" value="https://yourvisionaccount.cognitiveservices.azure.com/" />
    
**VisionSubscriptionKey** and **VisionEndpoint**

Follow this article to [Create a Cognitive Services](https://docs.microsoft.com/en-us/azure/cognitive-services/cognitive-services-apis-create-account?tabs=multiservice%2Cwindows) or go directly to [Get the keys for your resource](https://docs.microsoft.com/en-us/azure/cognitive-services/cognitive-services-apis-create-account?tabs=multiservice%2Cwindows#get-the-keys-for-your-resource) and your Endpoint.

![Image](https://docs.microsoft.com/en-us/azure/cognitive-services/media/cognitive-services-apis-create-account/get-cog-serv-keys.png)

### Translator Service
You'll need to configure the following 3 lines:

    <add key="TranslatorSubscriptionKey" value="insertyourkeyhere" />
    <add key="TranslatorEndpoint" value="https://api-eur.cognitive.microsofttranslator.com" />
	<add key="TranslationLang" value="fr" />
	
**TranslatorSubscriptionKey**

Follow [How to sign up for the Translator Text API](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/translator-text-how-to-signup)
Once you have the resource created, you can go to the quick start area and find your keys and endpoint

**TranslatorEndpoint**

Should be the generic api.cognitive.microsofttranslator.com. If you want to force a specific region check this [article
](https://docs.microsoft.com/bs-latn-ba/azure/cognitive-services/translator/reference/v3-0-reference). 

**TranslationLang**

check the language possibilities [here](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/reference/v3-0-languages) or call this service [directly](https://api.cognitive.microsofttranslator.com/languages?api-version=3.0).

### Web.config 
Here's the full list of parameters that should be configured for your services:

    <add key="StorageConnectionString" value="DefaultEndpointsProtocol=https;AccountName=yourstorageaccountname;AccountKey=yourstorageaccountkey;EndpointSuffix=core.windows.net" />
    <add key="VisionSubscriptionKey" value="insertyourkeyhere" />
    <add key="VisionEndpoint" value="https://yourvisionaccount.cognitiveservices.azure.com/" />
    <add key="TranslatorSubscriptionKey" value="insertyourkeyhere" />
    <add key="TranslatorEndpoint" value="https://api-eur.cognitive.microsofttranslator.com" />
    <add key="VideoIndexerAccountId" value="insertyouraccountidhere" />
    <add key="VideoIndexerLocation" value="Trial" />
    <add key="VideoIndexerSubscriptionKey" value="insertyourkeyhere" />
    <add key="TranslationLang" value="fr" />


## Running the web app on a video
You can run the web app, connect to Video Indexer and process the thumbnails by specifying the video Id.

To identify the video Id of your video, look to the URL in Video Indexer. Url will look like [https://www.videoindexer.ai/accounts/ad6cf452-26e0-46e3-b8fa-4551624f4532/videos/**bf2669d99d**/?location=Trial](https://www.videoindexer.ai/accounts/ad6cf452-26e0-46e3-b8fa-4551624f4532/videos/bf2669d99d/?location=Trial) in that case the Video is **bf2669d99d**

## Notes
Known issues
* When processing a video, the progress bar based on SignalR is seen by all users accessing the site
