#!/bin/bash

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Helper Functions @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

#################################################
# get_parameter_value 
# Function to ask a question and read user's input
##############################################
function get_parameter_value () {
    local question="$1"
    local variable="$2"

    read -p "$question: " input
    if [[ -n $input ]]; then
        eval "$variable=\"$input\""
    fi
}

##############################################
#  CLI Pre-requisites
###############################################
function install_cli_tools {
  # https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli
  echo "ensure you got the latest CLI client and install add ons if needed"
  echo "https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli"
  az extension add --name connectedk8s
  az extension add --name aks-preview
  az provider register --namespace Microsoft.Kubernetes
  az provider register --namespace Microsoft.KubernetesConfiguration
  az provider register --namespace Microsoft.ExtendedLocation
}

##################################################################
# Create Cognitive Services HOBO (On Behalf Of the User ) Resources
##################################################################
function create_cognitive_hobo_resources {
  echo -e "\t create Cognitive Services On VI RP ***start***"
  sleepDuration=10
  echo "getting arm token"
  createResourceUri="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}/CreateExtensionDependencies?api-version=${viApiVersion}"
  echo "=============================="
  echo "Creating cs resources"
  echo "=============================="
  result=$(az rest --method post --uri $createResourceUri 2>&1 >/dev/null || true)
  echo $result    

  if [[ "$result" == *"ERROR: Conflict"* ]]; then
    echo "CS Resources already exist. Moving on."
  else
    echo "No CS resources found. Creating"  
  fi
  getSecretsUri="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}/ListExtensionDependenciesData?api-version=${viApiVersion}"
  csResourcesData=$(az rest --method post --uri $getSecretsUri 2>&1 >/dev/null || true)
  if [[ "$csResourcesData" == *"ERROR"* ]]; then
    printf "\n"
    numRetries=0
    sleepDuration=10
    maxNumRetries=20
    while  [ $numRetries -lt $maxNumRetries ]; do
      csResourcesData=$(az rest --method post --uri $getSecretsUri 2>&1 >/dev/null || true)
      if [[ "$csResourcesData" == *"ERROR"* ]]; then
          numRetries=$(( $numRetries + 1 ))
          echo "Retrying to get CS resources data. Attempt $numRetries/$maxNumRetries"
          sleep $sleepDuration
      else
          break
      fi
    done
      printf "\n"
  fi

  echo "=============================="
  echo "Getting secrets"
  echo "=============================="
  printf "\n"
  if [[ "$csResourcesData" == *"ERROR:"* ]]; then
    echo "Error getting the cognitive services resources, please reach out to support"
  else 
    echo "Got CS resources"
  resultJson=$(az rest --method post --uri $getSecretsUri)
  fi  
  
  export speechPrimaryKey=$(echo $resultJson | jq -r '.speechCognitiveServicesPrimaryKey')
  export speechEndpoint=$(echo $resultJson | jq -r '.speechCognitiveServicesEndpoint')
  export translatorPrimaryKey=$(echo $resultJson | jq -r '.translatorCognitiveServicesPrimaryKey')
  export translatorEndpoint=$(echo $resultJson | jq -r '.translatorCognitiveServicesEndpoint')
  export ocrPrimaryKey=$(echo $resultJson | jq -r '.ocrCognitiveServicesPrimaryKey')
  export ocrEndpoint=$(echo $resultJson | jq -r '.ocrCognitiveServicesEndpoint')
  
  echo -e "\t create Cognitive Services On VI RP ***done***"
}

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Main Script @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#

#=============================================#
#============== Constants           ==========#
#=============================================#
install_aks_cluster="true"
install_extension="true"
register_cli_add_ons="true"
aksVersion="1.27.3" # https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli
viApiVersion="2023-06-02-preview" # VI API version

#=============================================#
#============== Parameters Customization =====#
#=============================================#
region="eastus" #default region , will be override later
extensionName="video-indexer" #default extension name , will be override later
resourcesPrefix="vi" #default resources prefix , will be override later
namespace="video-indexer" #default namespace , will be override later

# Ask questions and read user input
get_parameter_value "What is the Azure subscription ID during deployment?" "subscriptionId"
get_parameter_value "What is the name of the Video Indexer resource group during deployment?" "resourceGroup"
get_parameter_value "What is the name of the Video Indexer account name during deployment?" "accountName"
get_parameter_value "What is the name of the Video Indexer account Id during deployment?" "accountId"
get_parameter_value "What is the location of the Video Indexer during deployment?" "region"
get_parameter_value "Provide a unique identifier value during deployment.(this will be used for Cloud Resources : AKS, DNS names etc)?" "resourcesPrefix"
get_parameter_value "What is the Video Indexer extension name ?" "extensionName"
get_parameter_value "What is the extension kubernetes namespace to install to ?" "namespace"

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
#==============================================#

aks="${resourcesPrefix}-aks"
rg="${resourcesPrefix}-rg"
connectedClusterName="${resourcesPrefix}-connected-aks"
nodePoolRg="${aks}-agentpool-rg"
nodeVmSize="Standard_D4a_v4" # 4 vcpus, 16 GB RAM
workerVmSize="Standard_D32a_v4" # 32 vcpus, 128 GB RAM
tags="createdBy=vi-arc-extension"
#=========Install CLI Tools if needed =====================#
if [[ $install_cli_tools == "true" ]]; then
  install_cli_tools
fi

echo "================================================================"
echo "============= Deploying new ARC Resources ======================"
echo "================================================================"

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Deploy Infra @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#
if [[ $install_aks_cluster == "true" ]]; then
      echo "Deploying Resources: [Resource group: $rg, AKS: $aks, Connected-Cluster Name: ${connectedClusterName}]"
      echo "create Resource group"
      az group create --name $rg --location $region --output table --tags $tags

      echo -e "\t create aks cluster Name: $aks , Resource Group $rg- ***start***"
      az aks create -n $aks -g $rg \
            --enable-managed-identity\
            --kubernetes-version ${aksVersion} \
            --enable-oidc-issuer \
            --nodepool-name system \
            --os-sku AzureLinux \
            --node-count 2 \
            --tier standard \
            --generate-ssh-keys \
            --network-plugin kubenet \
            --tags $tags \
            --node-resource-group $nodePoolRg \
            --node-vm-size $nodeVmSize \
            --node-os-upgrade-channel NodeImage --auto-upgrade-channel node-image

      echo -e "\t create aks cluster Name: $aks , Resource Group $rg- ***done***"
      echo "Adding another worload node pool"
      az aks nodepool add -g $rg --cluster-name $aks  -n workload \
              --os-sku AzureLinux \
              --mode User \
              --node-vm-size $workerVmSize \
              --node-osdisk-size 100 \
              --node-count 0 \
              --max-count 10 \
              --min-count 0  \
              --tags $tags \
              --enable-cluster-autoscaler \
              --max-pods 110
      echo "Adding another workload node pool ***done***"
      #=============================================#
      #============== AKS Credentials ==============#
      #=============================================#
      echo -e  "\tConnecting to AKS and getting credentials  - ***start***"
      az aks get-credentials --resource-group $rg --name $aks --admin --overwrite-existing
      echo "AKS connectivity Sanity test"
      kubectl get nodes
      echo -e "\tconnect aks cluster - ***done***"
      #=============================================#
      #============== Add ingress controller =======#
      #=============================================#
      echo -e "\tAdding ingress controller -- ***start***"
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
      echo -e "\tAdding ingress controller -- ***done***"
      #=============================================#
      #========= Patch Public IP DNS Label =========
      #=============================================#    
      publicIpResourceId=$(az network public-ip list --resource-group $nodePoolRg --query "[?contains(name, 'kubernetes')].id" -otsv)
      echo "publicIpResourceId: $publicIpResourceId"
      az network public-ip update --ids $publicIpResourceId --dns-name ${resourcesPrefix}
      echo "Public IP DNS Label has been updated to ${resourcesPrefix}"
      
      #=============================================#
      #============== Create AKS ARC Cluster =======#
      #=============================================#
      echo -e "\tConnecting AKS to ARC-AKS -- ***start***"
      az connectedk8s connect --name ${connectedClusterName} --resource-group $rg --yes
      echo -e "\tconnecting AKS to ARC-AKS -- ***done***"
fi

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Deploy Video Indexer Extension @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#
if [[ $install_extension == "true" ]]; then
  #===============================================================================#
  #====== Creating Cognitive Services on Behalf of the user on VI RP =============#
  #===============================================================================#
  create_cognitive_hobo_resources

  echo "translatorEndpoint=$translatorEndpoint, speechEndpoint=$speechEndpoint, ocrEndpoint=$ocrEndpoint"

    if [[ -z $translatorEndpoint || -z $translatorPrimaryKey || -z $speechEndpoint || -z $speechPrimaryKey || -z $ocrEndpoint || -z $ocrPrimaryKey ]]; then
      echo "one of [ translatorEndpoint, translatorPrimaryKey, speechEndpoint, speechPrimaryKey, ocrEndpoint, ocrPrimaryKey]  is empty. Exiting"
      exit 1
    fi
  echo "==============================="
  echo "Installing VI Extenion into AKS Connected Cluster ${connectedClusterName} on ResourceGroup $rg"
  echo "==============================="
  ######################
  ENDPOINT_URI=$(az network public-ip list --resource-group $nodePoolRg --query "[?contains(name, 'kubernetes')].dnsSettings.fqdn" -otsv)
  echo "Check If ${extensionName} extension is already installed"
  exists=$(az k8s-extension list --cluster-name ${connectedClusterName} --cluster-type connectedClusters -g $rg --query "[?name=='${extensionName}'].name" -otsv)
  
  if [[ $exists == ${extensionName} ]]; then
    echo -e "\tExtension Found - Updating VI Extension - ***start***"
    az k8s-extension update --name ${extensionName} \
                          --cluster-name ${connectedClusterName} \
                          --resource-group ${rg} \
                          --cluster-type connectedClusters \
                          --auto-upgrade-minor-version true \
                          --config-protected-settings "speech.endpointUri=${speechEndpoint}" \
                          --config-protected-settings "speech.secret=${speechPrimaryKey}" \
                          --config-protected-settings "translate.endpointUri=${translatorEndpoint}" \
                          --config-protected-settings "translate.secret=${translatorPrimaryKey}" \
                          --config-protected-settings "ocr.endpointUri=${ocrEndpoint}" \
                          --config-protected-settings "ocr.secret=${ocrPrimaryKey}"\
                          --config "videoIndexer.accountId=${accountId}" \
                          --config "frontend.endpointUri=https://${ENDPOINT_URI}"
    echo -e "\tUpdating VI Extension - ***done***"
  else  
    echo -e "\tCreate New VI Extension - ***start***"
    az k8s-extension create --name ${extensionName} \
                              --extension-type Microsoft.videoindexer \
                              --scope cluster \
                              --release-namespace ${namespace} \
                              --cluster-name ${connectedClusterName} \
                              --resource-group ${rg} \
                              --cluster-type connectedClusters \
                              --auto-upgrade-minor-version true \
                              --config-protected-settings "speech.endpointUri=${speechEndpoint}" \
                              --config-protected-settings "speech.secret=${speechPrimaryKey}" \
                              --config-protected-settings "translate.endpointUri=${translatorEndpoint}" \
                              --config-protected-settings "translate.secret=${translatorPrimaryKey}" \
                              --config-protected-settings "ocr.endpointUri=${ocrEndpoint}" \
                              --config-protected-settings "ocr.secret=${ocrPrimaryKey}"\
                              --config "videoIndexer.accountId=${accountId}" \
                              --config "frontend.endpointUri=https://${ENDPOINT_URI}" \
                              --config "storage.storageClass=azurefile-csi" \
                              --config "storage.accessMode=ReadWriteMany" 
    echo -e "\tCreate New VI Extension - ***done***"
  fi
fi  

echo "==============================="
echo "VI Extension is installed"
echo "==============================="