
# Quickstart: Deploy Azure Video Analyzer for Media with ARM Template 

## Overview

In this Tutorial you will create an Azure Video Analyzer for Media with all its dependent Azure resources.

The resource will be deployed to your subscription and will create the following resources: 

- Resource Group
- Managed Identity
- Storage Account
- Azure Media Services Account
- Azure Video Analyzer for Media.
<br>

> **Notes:**
> - this sample is *not* for connecting an existing Azure Video Analyzer for Media classic account to an ARM-Based Video Analyzer for Media account.
> - this sample does not cover the usage of Terraform and its various CLI options. <br> for more information about Terraform please visit https://www.terraform.io/intro



## Prerequisites

* An Azure Subscription 
* Terraform Client - (https://www.terraform.io/downloads)

## Deploy the sample

----

### Step 1 : Fill-In missing environemnt variables

1. Open The [variables.rf File](./variables.tf) file and inspect its content.
2. Fill in the required parameters such as 

- resource group name
- location
- tags
- tenant_id and subscription_id
- prefix string used for various azure resource name.

> The sample assumes you are authenticated to your Azure Subscription and has the permissions to deploy resources.<br>
>For more information about how terraform client authenticats to Azure visit [Authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) on the terraform docs.


### Step 2 : Create Terraform Plan

1. Open your terminal on the solution path and type 

```powershell
terraform init
```
in order to install required dependencies and libraries.

2. Next run the `plan` command in order to view the changes that are about to be deployed to Azure.

```powershell
terraform plan
```

3. Run the apply command, and approve it when terraform CLI asks for confirmation.

```powershell
terraform apply
```

or , run it without confirmation prompt : 
```powershell
terraform apply -auto-approve
```

4. Wait for the script completion and view the resource output information.


### Notes

## Reference Documentation

If you're new to Azure Video Analyzer for Media (formerly Video Indexer), see:


* [Azure Video Analyzer for Media Documentation](https://aka.ms/vi-docs)
* [Azure Video Analyzer for Media Developer Portal](https://aka.ms/vi-docs)

* After completing this tutorial, head to other Azure Video Analyzer for media Samples, described on [README.md](../../README.md)

If you're new to template deployment, see:

* [Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)
* [Deploy Resources with ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)
* [Terraform Deployment Docs](https://www.terraform.io/intro)

