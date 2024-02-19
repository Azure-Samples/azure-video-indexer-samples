
#!/bin/bash
set -e
export SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

deploy_name=videploy
#########Fill In The missing Propperties#########
subscription="<Your Subscription ID>"
resource_group="<Your Resource Group Name>"
location="eastus"
#################################################

#Template
parameters_file="main.parameters.json"
template_file="main.bicep"

# Login to Azure
az login --use-device-code
az account set -s $subscription

# Create Resource Group
echo "Create Resource Group"
az group create -n ${resource_group} -l $location

# Deploy the bicep file
echo "Deploy Resources"
az deployment group create -g $resource_group --name $deploy_name \
                        --template-file $template_file \
                        --parameters $parameters_file