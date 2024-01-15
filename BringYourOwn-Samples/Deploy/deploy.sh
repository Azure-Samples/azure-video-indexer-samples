
#!/bin/bash
set -e
export SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
echo $(dirname 0)

location=eastus
resource_prefix=byo
storage_account="${resource_prefix}sa"
resource_group="${resource_prefix}-rg"
application_name="${resource_prefix}-app"
deploy_name=byodeploy
deploy_infra=true
deploy_app=true
ZipContainerName=${ZIP_CONTAINER:-functions}

#Template
parameters_file="main.parameters.json"
template_file="main.bicep"


# Login to Azure
az login --use-device-code
az account set -s "<Place_Your_Subscription_Here>"

if [ $deploy_infra = true ]; then
    echo "Create Resource Group"
    az group create -n ${resource_group} -l $location

    echo "Deploy Resources"
    az deployment group create -g $resource_group --name $deploy_name \
                            --template-file $template_file \
                            --parameters $parameters_file \
                            --parameters deploymentNameId=${deploy_name}-1 resourceNamePrefix=${resource_prefix}
fi

if [ $deploy_app = true ]; then
    echo "deploy function app"
    cd ${SCRIPT_PATH}/../Src/
    rm -rf bin/publish
    dotnet publish CarDetectorFuncApp/CarDetectorApp.csproj -c Release -o bin/publish
    echo "zipping function app solution"
    cd bin/publish
    zip -r - . >../../func.zip
    cd ../../
    echo "uploading to Azure Functions"
    az functionapp deployment source config-zip -g ${resource_group}  -n ${application_name} --src ./func.zip
fi

