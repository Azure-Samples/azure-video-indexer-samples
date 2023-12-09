
#!/bin/bash
set -e
export SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
echo $(dirname 0)

subscription="<Place Your Subscription ID Here>"
location="<Place Your Location Here>"
resource_prefix='<Place Your Resource Prefix Here>'
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
                        --parameters $parameters_file \
                        --parameters deploymentNameId=${deploy_name}-1 resourceNamePrefix=${resource_prefix}

