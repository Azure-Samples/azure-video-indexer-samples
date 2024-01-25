
# Quickstart: Deploy Azure Video Indexer with ARM Template 

## Overview

In this Quick-Start you will create an Azure Video Indexer  account by using ARM template (PREVIEW)

The resource will be deployed to your subscription and will create the Azure Video Indexer resource based on parameters defined in the videoindexer.template file.


> **_Note_:**
> this sample is *not* for connecting an existing Azure Video Indexer classic account to an ARM-Based Video Indexer account.

> For full documentation on Azure Video Indexer API, visit the [Developer Portal](https://api-portal.videoindexer.ai/) page.

> The current API Version is "2022-08-01". Check this Repo from time to time to get updates on new API Versions.

## Prerequisites

* An Azure Media Services (AMS) account. You can create one for free through the [Create AMS Account](https://docs.microsoft.com/en-us/azure/media-services/latest/account-create-how-to).

* In case you are interested in creating the Full End-To-End Media Solution that Creates Azure Media Service Account, Storage Account with all the permissions correctly wired, please check the [Create Media Solution - Terraform](../Create-Media-Solution-Terraform/) Demo. 

## Deploy the sample

----

### Option 1: Click the "Deploy To Azure Button", and fill in the missing parameters


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fmedia-services-video-indexer%2Fmaster%2FDeploy-Samples%2FArmTemplates%2Fvideoindexer.template.json)

----

### Option 2 : Deploy using Power Shell Script

1. Open The [Template File](videoindexer.template.json) file and inspect its content.
2. Fill in the required parameters (see below)
3. Run the Following Power Shell commands:

* Create a new Resource group on the same location as your Azure Video Indexer account, using the [New-AzResourceGroup](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup) cmdlet.


```powershell
New-AzResourceGroup -Name myResourceGroup -Location eastus
```

* Deploy the template to the resoruce group using the [New-AzResourceGroupDeployment](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment) cmdlet.

```powershell
New-AzResourceGroupDeployment -ResourceGroupName myResourceGroup -TemplateFile ./videoindexer.template.json
```

> **_Note_:**
> If you would like to work with bicep format, inspect the [bicep folder](../bicep/) on this repo.

## Parameters

### name


* Type: string

* Description: Specifies the name of the new Azure Video Indexer account.

* required: true

### location


* Type: string

* Description: Specifies the Azure location where the Azure Video Indexer account should be created.

* Required: false


> **_Note_:**
> You need to deploy Your Azure Video Indexer account in the same location (region) as the associated Azure Media Services(AMS) resource exists.


### mediaServiceAccountResourceId

* Type: string

* Description: The Resource ID of the Azure Media Services(AMS) resource.

* Required: true


### managedIdentityId

* Type: string

* Description: The Resource ID of the Managed Identity used to grant access between Azure Media Services(AMS) resource and the Azure Video Indexer account.

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
