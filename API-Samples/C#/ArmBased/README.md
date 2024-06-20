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
3. Go to Program.cs and populate `ViAccountName` with your account name
4. Go to Program.cs and populate `VideoUrl` with your video url
5. Go to Program.cs and Populate `ExcludedAI` with the AI's you want to exclude from the indexing job.
6. Go to Program.cs and Populate `VideoUrl` and `LocalVideoPath` with publicly accessed video Url and/or with local path to video file.
7. Review the VideoIndexerClient/VideoIndexerClient.cs file to learn about the implementation of the API. The Client is a convineint Http Wrapper 
around REST calls, and can be replaced easily with your custom behavior.  Note the section of issuing Video Indexer Access Token.
(The Token is Valid for 30 minutes) .

8. make sure dotnet 6.0 is installed. if not, please install https://dotnet.microsoft.com/download/dotnet/6.0
9. Open your terminal and navigate to "ApiUsage\ArmBased" folder
10. Run dotnet build

For more information visit [here](https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis)

<!--
Outline the required components and tools that a user might need to have on their machine in order to run the sample. This can be anything from frameworks, SDKs, OS versions or IDE releases.
-->

# Authentication Model

This sample presents two way to authenticate the running code to the video indexer account . 

1. Using Default Azure Credentials - Uses the logged in User ( or User Assigned Managed Identity/ System Assigned Identity ) that is logged to the running host.
2. Using Service Principal Authentication ( Entra App Registration)



## Authentication with Default Azure Credetials 

1. Ensure you are logged in to your azure subscription by running the `az login`  command
2. In case you run with the same user on multiple Tenants , set the tenantId variable under the `AccountTokenProvider.cs` class .
3. Extract the logged in user or MI object Id and move on to Section 3 below.


## Authentication with Default Azure Credetials 

1. create Azure Entra Id App that will be used as service principal 

```
az ad sp create-for-rbac --role Owner --display-name $appName --scopes /subscriptions/$SUBSCRIPTION_ID 
```

2. Extract the Service Principla Id ,and continue to section 3 below.


```
servicePrincipalId=$(az ad sp list --display-name $appName --query "[0].id" -o tsv)
```

3. In Both cases, the logged in service principal ( either user, Managed Identity or Entra App) need to have the `contributor` role on the video indexer account.
replace the SUBSCRIPTION_ID,RESOURCE_GROUP and VIDEO_INDEXER_ACCOUNT_NAME and servicePrincipalId with your values, and run the following command :

```
videoIndexerId="/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP/providers/Microsoft.VideoIndexer/accounts/VIDEO_INDEXER_ACCOUNT_NAME"
az role assignment create --assignee $servicePrincipalId --role "Contributor" --scope $videoIndexerId
```

## Usage

Run dotnet run

# Additional Reading
- [Authenticate with Azure CLI](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
- [Create Entra Id App for Rbac Permission](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)



