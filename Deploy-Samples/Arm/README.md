
# Quickstart: Deploy Azure Video Indexer with ARM Template 

## Overview

In this Quick-Start you will create an Azure Video Indexer account by using ARM template

The resource will be deployed to your subscription and will create the Azure Video Indexer resource based on parameters defined in the [videoindexer.parameters.json](./videoindexer.parameters.json)

The Following Resources will be installed using the Bicep template:

- Azure Storage Account
- Azure Video Indexer Account with connection to the Storage Account using System Assigned Identity
- The `Storage Blob Data Contributor` Role Assignment for Video Indexer Account on the Storage Account.
<br></br>
> **_Note_:**
> On June 30, 2023, Azure Media Services announced the planned retirement of their product. Please read Video Indexer's updated release notes to understand the impact of the Azure Media Services retirement on your Video Indexer account.[AMS Retirement Impact](https://learn.microsoft.com/en-us/azure/azure-video-indexer/release-notes#june-2023)

> For full documentation on Azure Video Indexer API, visit the [Developer Portal](https://api-portal.videoindexer.ai/) page.

> The current API Version is "2024-01-01". Check this Repo from time to time to get updates on new API Versions.

## Prerequisites
Before deploying the Bicep items, please ensure that you have the following prerequisites installed:

- Azure subscription with permissions to create Azure resources
- The latest version of [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli). 

## Deploy the sample

----

### Option 1: Click the "Deploy To Azure Button", and fill in the missing parameters

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-video-indexer-samples%2Fmaster%2FDeploy-Samples%2FArm%2Fvideoindexer.template.json)

----

### Option 2 : Deploy using Az CLI

1. Open The [Template File](videoindexer.template.json) file and inspect its content.
2. Open The [Parameter File](videoindexer.parameters.json) file and Fill in the required parameters (see below).
3. Run the Following Az CLi Command:

* Create a new Resource group on the same location as your Azure Video Indexer account, using the [New-AzResourceGroup](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup) cmdlet.


```shell
az group create -n myResourceGroup -l eastus 
```

* Deploy the template to the resoruce group using the [az deployment group create](https://learn.microsoft.com/en-us/cli/azure/deployment/group?view=azure-cli-latest#az-deployment-group-create) command.

```shell
az deployment group create \
--resource-group myResourceGroup \
--template-file .\videoindexer.template.json \
--parameters=.\videoindexer.parameters.json  

```

> **_Note_:**
> If you would like to work with bicep format, inspect the [bicep folder](../bicep/) on this repo.

## Parameters

### name


* Type: string

* Description: Specifies the name of the new Azure Video Indexer account.

* required: true


### storageAccountName

* Type: string

* Description: The Name of the storageAccount that will be used by Video Indexer Account.

* Required: true


### tags


* Type: object

* Description: Array of objects that represents custom user tags on the Azure Video Indexer account

 Required: false


### Notes

## Reference Documentation

If you're new to Azure Video Indexer , see:


* [Azure Video Indexer Documentation](https://aka.ms/vi-docs)
* [Azure Video Indexer Developer Portal](https://aka.ms/videoindexer-dev-portal)

* After completing this tutorial, head to other Azure Video Indexer Samples, described on [README.md](../../README.md)

If you're new to template deployment, see:

* [Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)
* [Deploy Resources with ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)
* [Deploy Resources with Bicep and Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli)
