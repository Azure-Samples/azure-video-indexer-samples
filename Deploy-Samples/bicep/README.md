
# Quickstart: Deploy Azure Video Indexer with ARM Template 

## Overview

In this Quick-Start you will create an Azure Video Indexer account by using bicep template

The resource will be deployed to your subscription and will create the Azure Video Indexer resource based on parameters defined in the [main.parameters.json](./main.parameters.json) file and the [deploy.sh](./deploy.sh) script.

The Following Resources will be installed using the Bicep template:

- Azure Storage Account
- Azure Media Services Account that uses the Storage Account
- Azure Video Indexer Account with connection to the Media Services using System Assigned Identity
- Azure EventHubs Namesapce with an EventHub instance to store incoming Video indexer Logs
- Diagnostics Settings attached to the Azure Video Indexer to direct the Video Indexer Logs into the EventsHub namespace
- Roles and Permission for the Event Hubs Writing and for the Video Indexer on the Media Service Account.


> **Note:**
> On June 30, 2023, Azure Media Services announced the planned retirement of their product. Please read Video Indexer's updated release notes to understand the impact of the Azure Media Services retirement on your Video Indexer account.[AMS Retirement Impact](https://learn.microsoft.com/en-us/azure/azure-video-indexer/release-notes#june-2023)

> **Note:**
> this sample is *not* for connecting an existing Azure Video Indexer classic account to an ARM-Based Video Indexer account.


## Prerequisites

1. Get the latest version of  [AZ CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and make sure `az login` is successful
 
## Edit The Properties

1. Open the [main.parameters.json](./main.parameters.json) file and fill in the missing parameters
2. Open the [deploy.sh](./deploy.sh) script file and fill in subscription Id ,region and resource prefixes names.

## Deploy the sample

----

### Option 1: Click the "Deploy To Azure Button", and fill in the missing parameters


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fmedia-services-video-indexer%2Fmaster%2FDeploy-Samples%2FArm%2Fmain.bicep)

----

### Option 2 : Manual Deploy

Run the Following command from Linux shell terminal:

```bash
./deploy.sh
```

The script will create a resource group if it does not exist and deploy the bicep template to Azure.

## Parameters

### appServicePrincipalId


* Type: string

* Description: Specifies the principal Id (a.k.a ObjectId) of a service Prinicipal that will have a permission to write the VI Logs into the EventHubs namespace stream.

* required: true


### Notes

## Reference Documentation

If you're new to Azure Video Indexer , see:


* [Azure Video Indexer Documentation](https://aka.ms/vi-docs)
* [Collection And Routing Video Indexer Events](https://learn.microsoft.com/en-us/azure/azure-video-indexer/monitor-video-indexer)
* [Azure Video Indexer Developer Portal](https://aka.ms/avam-dev-portal)

* After completing this tutorial, head to other Azure Video Indexer Samples, described on [README.md](../../README.md)

If you're new to template deployment, see:

* [Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)
* [Deploy Resources with ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)
* [Deploy Resources with Bicep and Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli)
