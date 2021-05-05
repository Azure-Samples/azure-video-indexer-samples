# Infrastructure and Deployment

This folder contains Terraform script(s) which will deploy the solution to a given Azure Subscription. This file talks through the high level steps of getting up and running for development.

The code within this section is intended to be run with VSCode Dev Container.

> WARNING: Current infrastructure doesn't support VNET isolation for storage account and should only be used with non-sensitive public data.

## Quick Start

Before doing anything, you must [configure your environment first](#Configuring%20your%20environment)

To deploy your code run:

```bash
pwsh -c 'Invoke-psake make.ps1 tf-deploy'
```

To deploy your code and run the tests straight afterwards:

```bash
pwsh -c 'Invoke-psake make.ps1 deploy-and-check'
```

To deploy your code without building the .net code run:

```bash
NO_BUILD=true pwsh -c 'Invoke-psake ./make.ps1 tf-deploy'
```

## Open in the dev container in VSCode

This process will go through the steps of opening this repository in the Visual Studio Code (VSCode) dev container.

1. Get the latest version of [VSCode](https://code.visualstudio.com/)

1. Get the latest version of [Docker Desktop](https://www.docker.com/products/docker-desktop) and make sure it is running

1. Get the latest version of  [AZ CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and make sure `az login` is successful

1. Clone the `AI-Enrichment-Pipeline` repository locally

1. Open the root folder of the `AI-Enrichment-Pipeline` repository in VSCode

1. VSCode should prompt you to `Reopen in Container`, do that. If it doesn't, run `CTRL+SHIFT+P` -> `Reopen in container`

1. Wait for VSCode to load the repository, it can take several minutes, especially for the first time. You should see a green section at the bottom left which says "Dev Container: enrichmentpipelinecogservices" when it is done

## Configure VSCode tooling for Terraform

1. Follow the steps in "Open in the Dev Container" in this document

1. In the VSCode terminal, run `pwsh -c 'Invoke-psake ./make.ps1 tf-checks'`. You should see "psake succeeded executing ./make.ps1" when it has successfully completed

   > This executes [`terraform init` which is a requirement for the autocompletion to work in VSCode](https://github.com/hashicorp/vscode-terraform/#getting-started)
   > Error-Fix : If a server error persists, (e.g 403 Server failed to authenticate the request) reboot computer due to possible outdated token cached that prohibits connection to azure.

1. In VSCode, run `CTRL+SHIFT+P` -> `Terraform: Enable language server`

1. In the VSCode terminal, run `CTRL + C` to exit to the main bash shell

You should now have autocompletion and tooling for editing the terraform in VSCode

## Configuring your environment

1. In the VSCode terminal, run `az account list` to ensure you are authenticated into the correct subscription. If not, run `az login` and follow the steps to sign in with whichever account you need to access the subscription you wish to deploy it in. This will involve opening the browser at https://login.microsoftonline.com/common/oauth2/deviceauth, entering the code given in the terminal, choosing an account and logging in. The terminal will show some JSON when you have authenticated

   > If you already have `azurecli` installed on your machine and logged in, the dev container will use these details and there is no need to login again in the dev container.

1. Make a copy of the `./infra/example.vars.tfvars` file and name it `./infra/vars.auto.tfvars`

1. Complete `vars.auto.tfvars` with values to match you account and subscription. Get `vi_api_key` from https://api-portal.videoindexer.ai/developer > primary key

   > Other settings can stay as default unless you want to change them, but be aware some explicitly require you to change them
   > This file is excluded from git so it is acceptable to put secrets in here

## Deploy infrastructure via Terraform

Follow these steps to deploy the infrastructure and application code from source control to a specified Azure subscription.

1. Follow the steps in "Configure VSCode tooling for Terraform" in this document

1. In the VSCode terminal, run `pwsh -c 'Invoke-psake make.ps1 tf-deploy'`. It can take several minutes to complete. Wait for the "psake succeeded executing make.ps1" success message

> Note: You can set the `NO_BUILD` environment variable to skip building the `C#` functions before deployment. This is useful if you are testing a deployment and want to speed things up. To use this feature run `NO_BUILD=true pwsh -c 'Invoke-psake ./make.ps1 "tf-deploy"'`.

If you access the [Azure Portal](https://portal.azure.com) now, you will see a resource group with the name you set in `vars.auto.tfvars` with a selection of resources in it, including the Logic App.

## Start again and re-deploy infrastructure via Terraform

Sometimes it is necessary to start from fresh and re-deploy everything. 

This assumes that you have already followed "Deploy infrastructure via Terraform" at least once.

1. Delete the resource group(s) that were previously created by Terraform in your Azure subscription

1. Delete the `./infra/terraform.tfstate` file

   > This file is not in git so it is acceptable to delete your local copy without affecting other people

1. Re-run the steps in "Deploy infrastructure via Terraform"

## Continuous Integration

The main `tf-deploy` task in `make.ps1` will undertaken certain checks on the solution including:

- DotNet build and tests
- Terraform validation and linting

There is an Azure DevOps CI pipeline at `azure-pipelines.yml` which check the following:

- DotNet build and tests
- JSON validation for logic apps 
- Terraform validation

If the repository is hosted on Azure DevOps, this yml file can be configured as a pipeline for CI and used as part of a branch policy for merging into the `main` branch.

## Testing your deployment

For more information about how to test your deployment [please refer to the notes available here](./../scripts/README.md)

## Debugging deployment

1. Edit the config
1. Run `tf-deploy` task as normal
1. When failure occurs review the logs, edit the config then taint the VM with the command below and reattempt `tf-deploy`

If you see something like this:

```
Error: A resource with the ID "..." already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_virtual_machine_extension" for more information.
```

Go to the portal or use azbrowse to manually remove the extension from the VM or taint the VM and reattempt a `tf-deploy`