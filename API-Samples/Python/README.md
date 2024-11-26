---
page_type: How to use AVAM API
languages:
  - Python
products:
  - azure-video-analyzer-for-media
description: "Video Indexer API"
---

# Official Applied AI services| Video Indexer API page

<!--
Guidelines on README format: https://review.docs.microsoft.com/help/onboard/admin/samples/concepts/readme-template?branch=master

Guidance on onboarding samples to docs.microsoft.com/samples: https://review.docs.microsoft.com/help/onboard/admin/samples/process/onboarding?branch=master

Taxonomies for products and languages: https://review.docs.microsoft.com/new-hope/information-architecture/metadata/taxonomies?branch=master
-->

This folder contains the basic ways to address Video Indexer's API in order to allow full engagment with the product: Get Account, Get Access token through ARM API, upload a video, polling on status/waiting, and indexing the video.
It is highly recommend to first read the more detailed documentation which can be found [here](https://aka.ms/avam-arm-docs).

For more API abilities, please visit our [API documentation](https://api-portal.videoindexer.ai/)

## Contents

The sample code demonstrates important aspect of uploading and indexing a video for ARM-based accounts, availble from December 2021.
Following the code will give you a good idea of how to use our API for basic functionalities.
Make sure to read the inline comments and notice our best practices advices.
The main program to run the API samples is provided as a Jupyter notebook - video_indexer_api_samples.ipynb

This notebook provides samples for the following operations in Video Indexer:

1. Get account details.   
2. Upload a video from URL.   
2A. Upload a video from local file.   
3. Wait for the video to finish indexing.   
4. Search for video and get insights.
5. Use the Widgets API.   

## Prerequisites

Instructions:

1. Make sure you're logged-in with `az` to authenticate your account.   
2. Copy the `.env.example` file to a new file named `.env`, and update the values with your own account settings.
3. Make sure all requirements are installed. The list of requirements is provided in the file requirements.txt
4. Review the VideoIndexerClient/VideoIndexerClient.py file to learn about the implementation of the API. The Client can be replaced easily with your custom behavior.  Note the section of issuing Video Indexer Access Token.
(The Token is Valid for 30 minutes).
5. Run the cells in the Jupyter notebook - video_indexer_api_samples.ipynb

For more information visit [here](https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis)

<!--
Outline the required components and tools that a user might need to have on their machine in order to run the sample. This can be anything from frameworks, SDKs, OS versions or IDE releases.
-->
