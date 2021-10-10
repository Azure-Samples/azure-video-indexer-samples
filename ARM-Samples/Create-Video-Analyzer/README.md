
# Overview

In this Quick-Start you will create an Azure Analyzer for Media (a.k.a "AVAM") resource by using Arm Template.
The resource will be deployed to your subscription and will create the 'AVAM' resource based on parametrers presented on the avam.template file.

> **Note:**
> this sample is *not* for migrating an existing AVAM account to an ARM-Based AVAM account.
> For a full documentation on AVAM API, visit the [AVAM Developer Portal](https://aka.ms/avam-dev-portal) page.


## Prerequisites

* An Azure Media Service (AMS) account. You can get one for free through the [Create AMS Account](https://docs.microsoft.com/en-us/azure/media-services/latest/account-create-how-to).

## Deploy the sample

### Option 1 : Click the "Deploy To Azure Button", and fill in the missing parameters

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fmedia-services-video-indexer%2Ffeature%2Ftshaiman%2Farm-demo%2FARM-Samples%2Favam.template.json)

### Option 2 : Deploy using Power Shell Script
* Open The avam.template.json file and inspect its content.

## Parameters

### name
- type: string
- description: Specifies the name of the new Azure Analyzer for Media Resource.
- required: true

### location
- type: string
- description: Specifies the Azure location where the AVAM resource should be created.
- required: false

> **Note:**
> You need to deploy Your Azure Video Analyzer For Media Account in the same region as the Azure Media Services account exists.

### mediaServicesAccountId
- type: string
- description: The Resource Id of the Azure Media Service Account. 
- required: true

### managedIdentityId
- type: string
- description: The Application Id Of the Managed Identity used to grant access between AVAM resource and the Azure Media Service Account resource
- required: false

### tags
- type: array
- description: Array of Objects that represents custom user tags on the AVAM resource
- required: false

### Notes

## Reference Documentation

If you're new to Video Analyzer, see :

- [Azure Video Analyzer for Media Documentation](https://aka.ms/vi-docs)
- [Azure Video Analyzer Developer Portal](https://aka.ms/vi-docs)


If you're new to template deployment, see:
- [Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)


`Tags: AzureAnalyzerForMedia, AzureMediaServices, Beginner`
