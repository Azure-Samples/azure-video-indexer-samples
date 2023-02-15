---
page_type: How to use AVAM API
languages:
  - C#
  - .Net
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

## Prerequisites

Instructions:

1. Go to Program.cs and populate `SubscriptionId` with your subscription id
2. Go to Program.cs and populate `ResourceGroup` with your resource group
3. Go to Program.cs and populate `AccountName` with your account name
4. Go to Program.cs and populate `VideoUrl` with your video url
5. make sure dotnet 6.0 is installed. if not, please install https://dotnet.microsoft.com/download/dotnet/6.0
6. Open your terminal and navigate to "ApiUsage\ArmBased" folder
7. Run dotnet build

For more information visit [here](https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis)

<!--
Outline the required components and tools that a user might need to have on their machine in order to run the sample. This can be anything from frameworks, SDKs, OS versions or IDE releases.
-->

## Usage

Run dotnet run
