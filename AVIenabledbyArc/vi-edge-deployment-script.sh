#!/bin/bash

#=============================================#
#============== Customization  ===============#
#=============================================#
install_aks_cluster="true"
install_extension="true"
viApiVersion="2023-06-02-preview" # VI API version
region="<Add_Your_Deploy_Region_Here>"
#Customize the following variables if you want to use a prefix for all resources. a min of 3 characters is required
groupPrefix="vi-arc"

#=============================================#
#============== Constants  ===================#
#=============================================#
$loc=$region
# review https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli to select a valid k8s version
aksVersion="1.27.3"
namespace="video-indexer"
extension_name="videoindexer"

###############Helper Functions################# 
# Function to ask a question and read user's input
# Usage: ask_question "What is your name?" "name"
ask_question() {
    local question="$1"
    local variable="$2"

    read -p "$question: " input
    if [[ -n $input ]]; then
        eval "$variable=\"$input\""
    fi
}
progress-bar() {
  local duration=${1}
  local elapsed=${2}
    already_done() { for ((done=0; done<$elapsed; done++)); do printf "▇"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" $(( (($elapsed)*100)/($duration)*100/100 )); }
    clean_line() { printf "\r"; }
    clean_line
    already_done; remaining; percentage
    clean_line
}
##############################
# create_cognitive_hobo_resources
# Creating Cognitive Services On VI RP, on behalf of the user
##############################
function create_cognitive_hobo_resources {
  echo -e "\t create Cognitive Services On VI RP ***start***"
  sleepDuration=10
  echo "getting arm token"
  createResourceUri="https://management.azure.com/subscriptions/${viSubscriptionId}/resourceGroups/${viResourceGroup}/providers/Microsoft.VideoIndexer/accounts/${viAccountName}/CreateExtensionDependencies?api-version=2023-06-02-preview"
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
  getSecretsUri="https://management.azure.com/subscriptions/${viSubscriptionId}/resourceGroups/${viResourceGroup}/providers/Microsoft.VideoIndexer/accounts/${viAccountName}/ListExtensionDependenciesData?api-version=${viApiVersion}"
  csResourcesData=$(az rest --method post --uri $getSecretsUri 2>&1 >/dev/null || true)
  if [[ "$csResourcesData" == *"ERROR"* ]]; then
    printf "\n"
    numRetries=0
    sleepDuration=1
    maxNumRetries=20
    while  [ $numRetries -lt $maxNumRetries ]; do
      csResourcesData=$(az rest --method post --uri $getSecretsUri 2>&1 >/dev/null || true)
      if [[ "$csResourcesData" == *"ERROR"* ]]; then
          numRetries=$(( $numRetries + 1 ))
          progress=$(( $numRetries*100/20 ))
          progress-bar 100 $progress; 
    sleep $sleepDuration
      else
          progress-bar 100 100; 
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
########################################################################

# Ask questions and read user input
ask_question "What is the Azure subscription ID during deployment?" "viSubscriptionId"
ask_question "What is the name of the Video Indexer resource group during deployment?" "viResourceGroup"
ask_question "What is the name of the Video Indexer account during deployment?" "viAccountName"
ask_question "What is the Video Indexer account ID during deployment?" "viAccountId"
ask_question "What is the desired Extension version for VI during deployment? Press enter will default to $version" "version"
ask_question "What is the desired API version for VI during deployment? Press enter will default to $viApiVersion" "viApiVersion"
ask_question "Provide a unique identifier value during deployment.(this will be used for AKS name with prefixes)?" "uniqueIdentifier"

while true; do
# Use the variables in your script as needed
echo "viAccountId: $viAccountId"
echo "viSubscriptionId: $viSubscriptionId"
echo "viResourceGroup: $viResourceGroup"
echo "viExtensionVersion: $version"
echo "viApiVersion: $viApiVersion"
echo "viAccountName: $viAccountName"
echo "region: $region"
echo "Unique Identifier: $uniqueIdentifier"

 read -p "Are the values correct? (yes/no): " answer
  case $answer in
    [Yy]*)
      break
      ;;
    [Nn]*)
      echo "Exiting the script..."
      exit 0
      ;;
    *)
      echo "Invalid input. Please enter Yes or No."
      ;;
  esac
done

echo "switching to $viSubscriptionId"
az account set --subscription $viSubscriptionId

#=============================================#

if [[ -z $uniqueIdentifier || -z $viAccountId ]]; then
    echo "Please provide the required parameters for Speech, Translate, and OCR resources in Azure: (viAccountId, uniqueIdentifier)"
    exit 1
fi

#==============================================#
echo "================================================================"
echo "============= Deploying new ARC Dev Resources =================="
echo "================================================================"

#=============================================#
#============== CLI Pre-requisites ===========#
#=============================================#
# https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli
echo "ensure you got the latest CLI client and install add ons if needed"
echo "https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli"
register_cli_add_ons="false"

if [[ $register_cli_add_ons == "true" ]]; then
   az extension add --name connectedk8s
   az extension add --name aks-preview
   az provider register --namespace Microsoft.Kubernetes
   az provider register --namespace Microsoft.KubernetesConfiguration
   az provider register --namespace Microsoft.ExtendedLocation
fi 

tags="team=${groupPrefix} owner=${uniqueIdentifier}"
prefix="${groupPrefix}-${uniqueIdentifier}-$loc"

aks="$prefix-aks"
rg="$prefix-rg"


echo "Resource Names: [ AKS: $aks, AKS-RG: $rg ]"

connectedClusterName="$prefix-connected-aks"
connectedClusterRg="${rg}"
nodePoolRg="${aks}-agentpool-rg"
nodeVmSize="Standard_D4a_v4" # 4 vcpus, 16 GB RAM
workerVmSize="Standard_D32a_v4" # 32 vcpus, 128 GB RAM
dnsPrefix="${groupPrefix}-${uniqueIdentifier}"
#######################################################################

if [[ $install_aks_cluster == "true" ]]; then
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
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/cloud/deploy.yaml
      echo -e "\tAdding ingress controller -- ***done***"
      #=============================================#
      #========= Patch Public IP DNS Label =========
      #=============================================#    
      publicIpResourceId=$(az network public-ip list --resource-group $nodePoolRg --query "[?contains(name, 'kubernetes')].id" -otsv)
      echo "publicIpResourceId: $publicIpResourceId"
      az network public-ip update --ids $publicIpResourceId --dns-name $dnsPrefix
      echo "Public IP DNS Label has been updated to $dnsPrefix"
      
      #=============================================#
      #============== Create AKS ARC Cluster =======#
      #=============================================#
      echo -e "\tConnecting AKS to ARC-AKS -- ***start***"
      az connectedk8s connect --name $connectedClusterName --resource-group $connectedClusterRg --yes --tags $tags
      echo -e "\tconnecting AKS to ARC-AKS -- ***done***"
fi

#===============================================================================#
#====== Creating Cognitive Services on Behalf of the user on VI RP =============#
#===============================================================================#
create_cognitive_hobo_resources

echo "translatorEndpoint=$translatorEndpoint, speechEndpoint=$speechEndpoint, ocrEndpoint=$ocrEndpoint"

if [[ -z $translatorEndpoint || -z $translatorPrimaryKey || -z $speechEndpoint || -z $speechPrimaryKey || -z $ocrEndpoint || -z $ocrPrimaryKey ]]; then
    echo "one of [ translatorEndpoint, translatorPrimaryKey, speechEndpoint, speechPrimaryKey, ocrEndpoint, ocrPrimaryKey]  is empty. Exiting"
    exit 1
fi
#=============================================#
#============== VI Extension =================#
#=============================================#
if [[ $install_extension == "true" ]]; then
  
  scope="cluster"
  echo "==============================="
  echo "Installing VI Extenion into AKS Connected Cluster $connectedClusterName on ResourceGroup $connectedClusterRg"
  echo "==============================="
  ######################
  
  
  #ENDPOINT_URI="${groupPrefix}-${uniqueIdentifier}.eastus.cloudapp.azure.com"
  ENDPOINT_URI=$(az network public-ip list --resource-group $nodePoolRg --query "[?contains(name, 'kubernetes')].dnsSettings.fqdn" -otsv)
  echo "Check If videoindexer extension is already installed"
  exists=$(az k8s-extension list --cluster-name $connectedClusterName --cluster-type connectedClusters -g $connectedClusterRg --query "[?name=='videoindexer'].name" -otsv)
  
  if [[ $exists == "videoindexer" ]]; then
    echo -e "\tExtension Found - Updating VI Extension - ***start***"
    az k8s-extension update --name ${extension_name} \
                          --cluster-name ${connectedClusterName} \
                          --resource-group ${connectedClusterRg} \
                          --cluster-type connectedClusters \
                          --auto-upgrade-minor-version true \
                          --config-protected-settings "speech.endpointUri=${speechEndpoint}" \
                          --config-protected-settings "speech.secret=${speechPrimaryKey}" \
                          --config-protected-settings "translate.endpointUri=${translatorEndpoint}" \
                          --config-protected-settings "translate.secret=${translatorPrimaryKey}" \
                          --config-protected-settings "ocr.endpointUri=${ocrEndpoint}" \
                          --config-protected-settings "ocr.secret=${ocrPrimaryKey}"\
                          --config "videoIndexer.accountId=${viAccountId}" \
                          --config "frontend.endpointUri=https://${ENDPOINT_URI}" \
                          --config AI.nodeSelector."beta\\.kubernetes\\.io/os"=linux \
                          --config "storage.storageClass=azurefile-csi" \
                          --config "storage.accessMode=ReadWriteMany" 
    echo -e "\tUpdating VI Extension - ***done***"

  else  
    echo -e "\tCreate New VI Extension - ***start***"
    az k8s-extension create --name ${extension_name} \
                              --extension-type Microsoft.videoindexer \
                              --scope cluster \
                              --release-namespace ${namespace} \
                              --cluster-name ${connectedClusterName} \
                              --resource-group ${connectedClusterRg} \
                              --cluster-type connectedClusters \
                              --auto-upgrade-minor-version true \
                              --config-protected-settings "speech.endpointUri=${speechEndpoint}" \
                              --config-protected-settings "speech.secret=${speechPrimaryKey}" \
                              --config-protected-settings "translate.endpointUri=${translatorEndpoint}" \
                              --config-protected-settings "translate.secret=${translatorPrimaryKey}" \
                              --config-protected-settings "ocr.endpointUri=${ocrEndpoint}" \
                              --config-protected-settings "ocr.secret=${ocrPrimaryKey}"\
                              --config "videoIndexer.accountId=${viAccountId}" \
                              --config "frontend.endpointUri=https://${ENDPOINT_URI}" \
                              --config AI.nodeSelector."beta\\.kubernetes\\.io/os"=linux \
                              --config "storage.storageClass=azurefile-csi" \
                              --config "storage.accessMode=ReadWriteMany" 
    echo -e "\tCreate New VI Extension - ***done***"
  fi
fi  

echo "==============================="
echo "VI Extension is installed"
echo "Swagger is available at: https://$EXTERNAL_IP/swagger/index.html"
echo "In order to replace the Extension version run the following command: az k8s-extension update --name videoindexer --cluster-name ${connectedClusterName} --resource-group ${connectedClusterRg} --cluster-type connectedClusters --release-train ${releaseTrain} --version NEW_VERSION --auto-upgrade-minor-version false"
echo "In order to delete the Extension run the following command: az k8s-extension delete --name videoindexer --cluster-name ${connectedClusterName} --resource-group ${connectedClusterRg} --cluster-type connectedClusters"
