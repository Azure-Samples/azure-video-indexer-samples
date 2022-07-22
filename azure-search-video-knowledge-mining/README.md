---
page_type: sample
languages:
- python
products:
- azure
description: "Video Knowledge Mining Solution"
urlFragment: azure-search-video-knowledge-mining
---

# Azure Cognitive Search - Video Knowledge Mining Extension

![architecture](./architecture.JPG "Archicture diagram")

# Demo site
[Video Knowledge Mining Demo](https://video-knowledge-mining.azurewebsites.net/)

# Extend Azure Cognitive Search
Extend [Azure Cognitive Search](https://docs.microsoft.com/azure/search/cognitive-search-concept-intro) capabilities enabling video transcripts and insights search, through an integration with [Azure Video Analyzer for Media (formerly Azure Video Indexer)](https://docs.microsoft.com/en-us/azure/azure-video-analyzer/video-analyzer-for-media-docs/video-indexer-get-started).


# Repo Architecture
This repo is a collection of two skills:  
* [start-video-indexing](azure-functions/start-video-indexing) (trigger a video indexing starting from a video upload in Azure Blob Storage)  
![architecture-start-video-indexing](azure-functions/start-video-indexing/start-video-indexer.png "Archicture diagram")

* [video-indexer-callback](azure-functions/video-indexer-callback) (callback from Azure Blob Storage and push data to Azure Cognitive Search and Azure Blob Storage)
![architecture-video-indexer-callback](azure-functions/video-indexer-callback/video-indexer-callback.png "Archicture diagram")

and required infrastructure to set up the solution:
* [Powershell script](infrastructure/powershell)
* [Python script](infrastructure/python)  
__NOTE :__ Both Powershell and Python setup will provide same results. With Python solution you have to create a [Service Principal](https://docs.microsoft.com/en-us/azure-stack/operator/azure-stack-create-service-principals?view=azs-2002) and enable it to access your Subscription or Resource Group.

# Web App
To deploy a video indexer enabled Knowledge Mining Solution Accelerator Web App, refer to this [Knowledge Mining Solution Accelerator with Video Indexer](https://github.com/ruoccofabrizio/azure-search-knowledge-mining)


## Video insights
* __Face detection__: Detects and groups faces appearing in the video.
* __Celebrity identification__: Video Indexer automatically identifies over 1 million celebrities—like world leaders, actors, actresses, athletes, researchers, business, and tech leaders across the globe. The data about these celebrities can also be found on various websites (IMDB, Wikipedia, and so on).
* __Account-based face identification__: Video Indexer trains a model for a specific account. It then recognizes faces in the video based on the trained model. For more information, see Customize a Person model from the Video Indexer website and Customize a Person model with the Video Indexer API.
* __Thumbnail extraction for faces ("best face")__: Automatically identifies the best captured face in each group of faces (based on quality, size, and frontal position) and extracts it as an image asset.
* __Visual text recognition (OCR)__: Extracts text that's visually displayed in the video.
* __Visual content moderation__: Detects adult and/or racy visuals.
* __Labels identification__: Identifies visual objects and actions displayed.
* __Keyframe extraction__: Detects stable keyframes in a video.

## Audio insights
* __Automatic language detection__: Automatically identifies the dominant spoken language. Supported languages include English, Spanish, French, German, Italian, Chinese (Simplified), Japanese, Russian, and Brazilian Portuguese. If the language can't be identified with confidence, Video Indexer assumes the spoken language is English. For more information, see Language identification model.
* __Multi-language speech identification and transcription (preview)__: Automatically identifies the spoken language in different segments from audio. It sends each segment of the media file to be transcribed and then combines the transcription back to one unified transcription. For more information, see Automatically identify and transcribe multi-language content.
* __Audio transcription__: Converts speech to text in 12 languages and allows extensions. Supported languages include English, Spanish, French, German, Italian, Chinese (Simplified), Japanese, Arabic, Russian, Brazilian Portuguese, Hindi, and Korean.
* __Closed captioning__: Creates closed captioning in three formats: VTT, TTML, SRT.
* __Two channel processing__: Auto detects separate transcript and merges to single timeline.
* __Noise reduction__: Clears up telephony audio or noisy recordings (based on Skype filters).
* __Transcript customization (CRIS)__: Trains custom speech to text models to create industry-specific transcripts. For more information, see Customize a Language model from the Video Indexer website and Customize a Language model with the Video Indexer APIs.
* __Speaker enumeration__: Maps and understands which speaker spoke which words and when.
* __Speaker statistics__: Provides statistics for speakers' speech ratios.
* __Textual content moderation__: Detects explicit text in the audio transcript.
* __Audio effects__: Identifies audio effects like hand claps, speech, and silence.
* __Emotion detection__: Identifies emotions based on speech (what's being said) and voice tonality (how it's being said). The emotion could be joy, sadness, anger, or fear.
* __Translation__: Creates translations of the audio transcript to 54 different languages.

## Audio and video insights (multi-channels)
When indexing by one channel, partial result for those models will be available.

* __Keywords extraction__: Extracts keywords from speech and visual text.
* __Named entities extraction__: Extracts brands, locations, and people from speech and visual text via natural language processing (NLP).
* __Topic inference__: Makes inference of main topics from transcripts. The 2nd-level IPTC taxonomy is included.
* __Sentiment analysis__: Identifies positive, negative, and neutral sentiments from speech and visual text.