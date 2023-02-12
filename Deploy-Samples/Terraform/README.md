
# Quickstart: Deploy Azure Video Indexer using Terraform (and ARM)

## Overview

In this tutorial you will create an Azure Video Indexer with all its dependent Azure resources.

The resource will be deployed to your subscription and will create the following resources:

- Resource Group
- Storage Account
- Azure Media Services Account
- Managed Identity
- Azure Video Indexer

> **Notes**:
>
> - This sample is *not* for connecting an existing Azure Video Indexer classic account to an ARM-Based Video Indexer account.
> - This sample does not cover the usage of Terraform and its various CLI options. For more information about Terraform please visit [Introduction to Terraform](https://www.terraform.io/intro).

## Prerequisites

- An Azure Subscription
- Azure CLI - [How to install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Terraform Client - [Download Terraform](https://www.terraform.io/downloads)

## Deploy the sample

----

### Step 1 : Fill-in missing terraform variables

1. Open the [variables.tf](./variables.tf) file and inspect its content.
2. Fill-in the required parameters:

- `tenant_id` : The tenant id which should be used to deploy resources.
- `subscription_id` : The subscription id which should be used to deploy resources.

3. Update default variable names if needed:

- `name`: The application name, used to name all resources.
- `environment`: The environment name, used to name all resources.
- `location`: The location of all resources.

> **Notes:**
>
> The sample assumes you are authenticated to your Azure Subscription and has the permissions to deploy resources.
> For more information about how terraform client authenticates to Azure visit [Authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) on the terraform docs.

### Step 2 : Apply terraform configuration files

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

or , run it without confirmation prompt:

```powershell
terraform apply -auto-approve
```

4. Wait for the script completion and view the resource output information.

## Reference Documentation

If you're new to Azure Video Indexer (formerly Video Indexer), see:

- [Azure Video Indexer Documentation](https://aka.ms/vi-docs)
- [Azure Video Indexer Developer Portal](https://aka.ms/vi-docs)
- After completing this tutorial, head to other Azure Video Indexer Samples, described on [README.md](../../README.md)

If you're new to template deployment, see:

- [Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)
- [Deploy Resources with ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)
- [Terraform Deployment Docs](https://www.terraform.io/intro)
