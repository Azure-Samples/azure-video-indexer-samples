
#!/bin/bash
set -e
export SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

#########Fill In The missing Propperties#########
subscription="24237b72-8546-4da5-b204-8c3cb76dd930"
location="eastus"
resource_prefix='tsdemo57'
#################################################

resource_group="${resource_prefix}-rg"
deploy_name=videploy

#Template
parameters_file="main.parameters.json"
template_file="main.bicep"

# Login to Azure
#az login --use-device-code
az account set -s $subscription

# Create Resource Group
echo "Create Resource Group"
az group create -n ${resource_group} -l $location

# Deploy the bicep file
echo "Deploy Resources"
az deployment group create -g $resource_group --name $deploy_name \
                        --template-file $template_file \
                        --parameters deploymentNameId=${deploy_name}-1 resourceNamePrefix=${resource_prefix}

