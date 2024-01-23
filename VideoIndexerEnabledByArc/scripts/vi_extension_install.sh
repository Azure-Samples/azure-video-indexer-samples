#!/bin/bash

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Helper Functions @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

#######################################
# region validation
# Ensure the user uses legal azure region name
#######################################
export valid_regions=($(az account list-locations --query "[].name" -o tsv))
function is_valid_azure_region() {
  local location=$1
  for reg in "${valid_regions[@]}"; do
    if [[ $reg == $location ]]; then
      return 0
    fi
  done
  return 1
}

function print_local_regions() {
  for reg in "${valid_regions[@]}"; do
    echo $reg
  done
}

##############################################
#  Get CS Auth Credentials
###############################################
function get_cs_auth_credentials {

  getSecretsUri="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}/ListExtensionDependenciesData?api-version=${viApiVersion}"
  numRetries=0
  sleepDuration=10
  maxNumRetries=30
  while :; do
    csResourcesData=$(az rest --method post --uri $getSecretsUri 2>&1 >/dev/null || true)

    if [[ "$csResourcesData" == *"ERROR"* ]]; then
      numRetries=$((numRetries + 1))
      echo "Retrying to get Cognitive Services resources credentials. Attempt $numRetries/$maxNumRetries"
      sleep $sleepDuration
    else
      echo "Cognitive Services resources credentials retrieved successfully."
      resultJson=$(az rest --method post --uri $getSecretsUri)
      export speechPrimaryKey=$(echo $resultJson | jq -r '.speechCognitiveServicesPrimaryKey')
      export speechEndpoint=$(echo $resultJson | jq -r '.speechCognitiveServicesEndpoint')
      export translatorPrimaryKey=$(echo $resultJson | jq -r '.translatorCognitiveServicesPrimaryKey')
      export translatorEndpoint=$(echo $resultJson | jq -r '.translatorCognitiveServicesEndpoint')
      export ocrPrimaryKey=$(echo $resultJson | jq -r '.ocrCognitiveServicesPrimaryKey')
      export ocrEndpoint=$(echo $resultJson | jq -r '.ocrCognitiveServicesEndpoint')
      break
    fi

    if [ $numRetries -ge $maxNumRetries ]; then
      echo "Max number of retries reached without getting Cognitive Service Secrets . Exiting script."
      printf "\n"
      exit 1
    fi
  done

}
##################################################################
# Create Cognitive Services HOBO (On Behalf Of the User ) Resources
##################################################################
function create_cognitive_hobo_resources {
  echo -e "\t create Cognitive Services On VI RP ***start***"
  sleepDuration=10
  createResourceUri="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}/CreateExtensionDependencies?api-version=${viApiVersion}"
  responseString=$(az rest --method post --uri $createResourceUri --verbose 2>&1 >/dev/null || true)
  responseStatusLine=$(echo "$responseString" | grep 'INFO: Response status:')
  responseStatus=$(echo "$responseStatusLine" | grep -oP '\d+')
  responseCode=$((responseStatus))

  if [[ "$responseCode" == 202 ]]; then
    echo "Cognitive Services resources are being created. Waiting for completion"
  elif [[ "$responseCode" == 409 ]]; then
    echo "Cognitive Services resources already exist. Moving on."
  else
    echo "an Unknown error occured: $responseStatus . Exiting"
    exit 1
  fi

  get_cs_auth_credentials
  echo -e "\t create Cognitive Services On VI RP ***done***"
}

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Main Script @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

#=============================================#
#============== Constants           ==========#
#=============================================#
aksVersion="1.28.2"               # https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli
viApiVersion="2023-06-02-preview" # VI API version

#=============================================#
#============== Parameters Customization =====#
#=============================================#
region="eastus"                     #default region , will be override later
extensionName="video-indexer"       #default extension name , will be override later
resourcesPrefix="vi"                #default resources prefix , will be override later
namespace="video-indexer"           #default namespace , will be override later
ENDPOINT_URI="127.0.0.1/vi" #default endpoint uri
version="1.0.41"                    #VI Extension version
singleNodeStorageClass="local-path" #default storage class for single node cluster
singleNodeAccessMode="ReadWriteOnce" #default access mode for single node cluster
region="eastus"
extensionName="vi-arc"
namespace="video-indexer"

subscriptionId=""
resourceGroup=""
accountName=""
accountId=""

#=============================================#
## Region Name Validation
region=${region,,}
if ! is_valid_azure_region "$region"; then
  echo "Invalid Azure region $region. Use one of the following regions:"
  print_local_regions
  exit 1
fi
echo "SubscriptionId: $subscriptionId"
echo "Azure Resource Group: ${resourceGroup}"
echo "Video Indexer AccountName: $accountName"
echo "Video Indexer AccountId: $accountId"
echo "Azure Resource prefixes: ${resourcesPrefix}"
echo "Region: $region"
echo "Video Indexer Extension Name: $extensionName"
echo "Video Indexer Extension Namespace: $namespace"

echo "switching to $subscriptionId"
az account set --subscription $subscriptionId
#=============================================#
#======== Create Connected-ARC Cluster =======#
#=============================================#
# Arc Enabled Connected Cluster Parameters
connectedClusterName="${resourcesPrefix}-connected-1n-kubeadm"
connectedClusterResourceGroup="${resourcesPrefix}-rg"
tags="createdBy=vi-arc-extension"
echo -e "\tConnecting AKS to ARC-AKS -- ***start***"
az group create --name ${connectedClusterResourceGroup} --location ${region} --output table --tags $tags
az connectedk8s connect --name ${connectedClusterName} --resource-group ${connectedClusterResourceGroup} --yes
echo "Performing AKS-Arc-connected connectivity Sanity test"
connectedResult=$(az connectedk8s show --name ${connectedClusterName} --resource-group ${connectedClusterResourceGroup} 2>&1)
if [[ "$connectedResult" == *"ERROR"* ]]; then
  echo "AKS-Arc-connected connectivity Sanity test failed. Exiting"
  exit 1
fi
#=====================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Deploy Video Indexer Extension @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#=====================================================================================================#
echo "================================================================"
echo "============= Deploying ARC Extension  ========================="
echo "================================================================"

create_cognitive_hobo_resources

echo "translatorEndpoint=$translatorEndpoint, speechEndpoint=$speechEndpoint, ocrEndpoint=$ocrEndpoint"

if [[ -z $translatorEndpoint || -z $translatorPrimaryKey || -z $speechEndpoint || -z $speechPrimaryKey || -z $ocrEndpoint || -z $ocrPrimaryKey ]]; then
  echo "one of [ translatorEndpoint, translatorPrimaryKey, speechEndpoint, speechPrimaryKey, ocrEndpoint, ocrPrimaryKey]  is empty. Exiting"
  exit 1
fi
echo "==============================="
echo "Installing VI Extenion into AKS Connected Cluster ${connectedClusterName} on ResourceGroup ${connectedClusterResourceGroup}"
echo "==============================="
######################
echo -e "\tCreate New VI Extension - ***start***"
az k8s-extension create --name ${extensionName} \
  --extension-type Microsoft.videoindexer \
  --scope cluster \
  --release-train stable \
  --version $version \
  --release-namespace ${namespace} \
  --cluster-name ${connectedClusterName} \
  --resource-group ${connectedClusterResourceGroup} \
  --cluster-type connectedClusters \
  --auto-upgrade-minor-version false \
  --config-protected-settings "speech.endpointUri=${speechEndpoint}" \
  --config-protected-settings "speech.secret=${speechPrimaryKey}" \
  --config-protected-settings "translate.endpointUri=${translatorEndpoint}" \
  --config-protected-settings "translate.secret=${translatorPrimaryKey}" \
  --config-protected-settings "ocr.endpointUri=${ocrEndpoint}" \
  --config-protected-settings "ocr.secret=${ocrPrimaryKey}" \
  --config "videoIndexer.accountId=${accountId}" \
  --config "frontend.endpointUri=https://${ENDPOINT_URI}" \
  --config "storage.storageClass=${singleNodeStorageClass}" \
  --config "storage.accessMode=${singleNodeStorageClass}" \
  --config "storage.indexing.accessModes={${singleNodeAccessMode}}" \
  --config "storage.models.accessModes={${singleNodeAccessMode}}" \
  --config "mssql.pvc.storageClass=${singleNodeStorageClass}"

echo -e "\tCreate New VI Extension - ***done***"

echo "==============================="
echo "VI Extension installed Successfully"
echo "In Order to delete the extension run: az k8s-extension delete --cluster-name ${connectedClusterName} --cluster-type connectedClusters -n ${extensionName} -g ${connectedClusterResourceGroup}  --yes"
echo "==============================="
