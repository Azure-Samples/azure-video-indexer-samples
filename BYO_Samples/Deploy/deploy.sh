
#!/bin/bash
set -e
export SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
echo $(dirname 0)
export SUBSCRIPTION="24237b72-8546-4da5-b204-8c3cb76dd930"
export LOCATION=eastus
export RESOURCE_PREFIX=byo1
export STORAGE_ACCOUNT="${RESOURCE_PREFIX}sa"
export RESOURCE_GROUP="${RESOURCE_PREFIX}-rg"
export APPLICATION_NAME="${RESOURCE_PREFIX}-app"
export DEPLOY_NANE=byodeploy241128
export deploy_infra=true
export deploy_app=false
export ZIP_CONTAINER=${ZIP_CONTAINER:-functions}

az account set -s $SUBSCRIPTION

if [ $deploy_infra = true ]; then
    echo "Create Resource Group"
    az group create -n ${RESOURCE_GROUP} -l $LOCATION

    echo "Deploy Resources"
    az deployment group create -g $RESOURCE_GROUP --name $DEPLOY_NANE \
                            --template-file .\\main.bicep \
                            --parameters deploymentNameId=${DEPLOY_NANE}-1 resourceNamePrefix=${RESOURCE_PREFIX}
fi

if [ $deploy_app = true ]; then
    echo "deploy function app"
    cd ${SCRIPT_PATH}/../../Src/
    rm -rf bin/publish
    dotnet publish FlorenceEnhancer/FlorenceEnhancer.csproj -c Release -o bin/publish
    echo "zipping function app solution"
    cd bin/publish
    zip -r - . >../../func.zip
    cd ../../
    echo "uploading to Azure Functions"
    az functionapp deployment source config-zip -g ${RESOURCE_GROUP}  -n ${APPLICATION_NAME} --src ./func.zip
fi

