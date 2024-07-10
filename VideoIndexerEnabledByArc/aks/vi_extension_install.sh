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
    for region in "${valid_regions[@]}"; do
        if [[ $region == $location ]]; then
            return 0
        fi
    done
    
    return 1
}
function print_local_regions() {
  for region in "${valid_regions[@]}"; do
    echo $region
  done
}
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
  az extension add --name k8s-extension
  az extension add --name aks-preview
  az provider register --namespace Microsoft.Kubernetes
  az provider register --namespace Microsoft.KubernetesConfiguration
  az provider register --namespace Microsoft.ExtendedLocation
}

function wait_for_cs_secrets {
  
  getSecretsUri="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${viResourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}/ListExtensionDependenciesData?api-version=${viApiVersion}"
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
# Create Cognitive Services HOBO (Host On Behalf Of ) Resources
##################################################################
function create_cognitive_hobo_resources {
  echo -e "\t create Cognitive Services On VI RP ***start***"
  sleepDuration=10
  createResourceUri="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${viResourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}/CreateExtensionDependencies?api-version=${viApiVersion}"
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

  wait_for_cs_secrets
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
install_cli_tools="true"
register_cli_add_ons="true"
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
get_parameter_value "What is the name of the Video Indexer resource group during deployment?" "viResourceGroup"
get_parameter_value "What is the name of the Video Indexer account name during deployment?" "accountName"
get_parameter_value "What is the Video Indexer account Id during deployment?" "accountId"
get_parameter_value "What is the location of the Video Indexer Extension running on ARC Connected Cluster?" "region"
get_parameter_value "Provide a unique identifier value during deployment.(this will be used for Cloud Resources : AKS, DNS names etc)?" "resourcesPrefix"
get_parameter_value "What is the Video Indexer extension name ?" "extensionName"
get_parameter_value "What is the extension kubernetes namespace to install to ?" "namespace"


## Region Name Validation
region=${region,,}
if ! is_valid_azure_region "$region"; then
  echo "Invalid Azure region $region. Use one of the following regions:"
  print_local_regions
  exit 1
fi
aksVersion=$(az aks get-versions --location $region --query "values[].patchVersions.keys(@)[][] | sort(@) | [-1]"  | tr -d '"')

echo "SubscriptionId: ${subscriptionId}"
echo "Video Indexer AccountName: ${accountName}"
echo "Video Indexer Resource Group: ${viResourceGroup}"
echo "Video Indexer AccountId: ${accountId}"
echo "Azure Resource prefixes: ${resourcesPrefix}"
echo "Region: $region"
echo "Video Indexer Extension Name: ${extensionName}"
echo "Video Indexer Extension Namespace: ${namespace}"
echo "Latest AKS Version: ${aksVersion}"
if [[ -z ${aksVersion} ]]; then
  echo "aksVersion is null or empty.Run `az aks get-versions --location $region` to get the latest AKS version on the selected region"
  exit 1
fi


echo "switching to $subscriptionId"
az account set --subscription $subscriptionId
#==============================================#

aks="${resourcesPrefix}-aks"
rg="${resourcesPrefix}-rg"
connectedClusterName="${resourcesPrefix}-connected-aks"
nodePoolRg="${aks}-agentpool-rg"
nodeVmSize="Standard_D4a_v4" # 4 vcpus, 16 GB RAM
workerVmSize="Standard_D32a_v4" # 32 vcpus, 128 GB RAM
summarizationWorkerVmSize="Standard_F32s_v2" # 32 vcpus, 64 GB RAM
tags="createdBy=vi-arc-extension"
#=========Install CLI Tools if needed =====================#
if [[ $install_cli_tools == "true" ]]; then
  install_cli_tools
fi


#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Deploy Infra @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#
if [[ $install_aks_cluster == "true" ]]; then
  echo "================================================================"
  echo "============= Deploying new ARC Resources ======================"
  echo "================================================================"

  echo "Deploying Kubernetes Resources: [AKS Name: $aks, AKS ResourceGroup: $rg,  Connected-Cluster Name: ${connectedClusterName}, Region: $region ]"
  echo "Create Kubernetes Resource group"
  az group create --name $rg --location $region --output table --tags $tags
#=======================================================================#
#======== Create AKS Cluster( Simulates User On Prem Infra) ============#
#=======================================================================#
  ## check if the cluster already exists 
  clusterExists=$(az aks show -n $aks -g $rg --query "name" -o tsv)
  if [[ ! -z $clusterExists ]]; then
    echo "AKS Cluster $aks already exists. Skipping AKS Cluster creation"
  else
    echo -e "\t create aks cluster Name: $aks , Resource Group $rg- ***start***"
    aks_create_result=$(az aks create -n $aks -g $rg \
      --enable-managed-identity\
      --enable-workload-identity \
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
      --enable-image-cleaner --image-cleaner-interval-hours 24 \
      --node-os-upgrade-channel NodeImage --auto-upgrade-channel node-image)

      if [[ $? -eq 0 ]]; then
        echo "AKS cluster creation succeeded"
      else
        echo "AKS cluster creation failed."
        exit 1
      fi
    ## Add maintanence window
    az aks maintenanceconfiguration add --resource-group $rg --cluster-name $aks --name aksManagedAutoUpgradeSchedule --schedule-type Weekly --day-of-week Friday --interval-weeks 3 --duration 8 --utc-offset +05:30 --start-time 00:00
    az aks maintenanceconfiguration add --resource-group $rg --cluster-name $aks --name aksManagedNodeOSUpgradeSchedule  --schedule-type Weekly --day-of-week Friday --interval-weeks 1 --duration 8 --utc-offset +05:30 --start-time 00:00
  fi

  echo -e "\t create aks cluster Name: $aks , Resource Group $rg- ***done***"
  echo "Adding two new node pool types, workload and workloadf32"
  #Check if the node pool already exists
  nodePoolExists=$(az aks nodepool show -g $rg --cluster-name $aks -n workload --query "name" -o tsv)
  if [[ ! -z $nodePoolExists ]]; then
    echo "Workload node pool already exists. Skipping node pool creation"
  else
    echo "Adding workload node pool"
    aks_nodecreate_output=$(az aks nodepool add -g $rg --cluster-name $aks  -n workload \
            --os-sku AzureLinux \
            --mode User \
            --node-vm-size $workerVmSize \
            --node-osdisk-size 100 \
            --node-count 0 \
            --max-count 10 \
            --min-count 0  \
            --tags $tags \
            --enable-cluster-autoscaler \
            --max-pods 110)
    if [[ $? -eq 0 ]]; then
      echo "Adding workload node pool succeeded"
    else
      echo "Adding workload node pool Failed. Exiting"
      exit 1
    fi
  fi  

  nodePoolSummarizationExists=$(az aks nodepool show -g $rg --cluster-name $aks -n workloadf32 --query "name" -o tsv)
  if [[ ! -z $nodePoolSummarizationExists ]]; then
    echo "workloadf32 node pool already exists. Skipping node pool creation"
  else
    echo "Adding workloadf32 node pool"
    aks_nodecreate_output_summary=$(az aks nodepool add -g $rg --cluster-name $aks  -n workloadf32 \
            --os-sku AzureLinux \
            --mode User \
            --node-vm-size $summarizationWorkerVmSize \
            --node-osdisk-size 100 \
            --node-count 0 \
            --max-count 5 \
            --min-count 0  \
            --tags $tags \
            --enable-cluster-autoscaler \
            --labels workload=summarization \
            --max-pods 110)
    if [[ $? -eq 0 ]]; then
      echo "Adding workloadf32 node pool succeeded"
    else
      echo "Adding workloadf32 node pool Failed. Exiting"
      exit 1
    fi
  fi
  echo "Adding two new node pool types, workload and workloadf32 ***done***"
  
  #=============================================#
  #============== AKS Credentials ==============#
  #=============================================#
  echo -e  "\tConnecting to AKS and getting credentials  - ***start***"
  if az aks get-credentials --resource-group $rg --name $aks --admin --overwrite-existing; then
    echo "AKS credentials retrieved successfully"
  else
    echo "Failed to retrieve AKS credentials"
    exit 1
  fi
  echo "AKS connectivity Sanity test"
  kubectl get nodes
  echo -e "\tconnect aks cluster - ***done***"
  #=============================================#
  #============== Add ingress controller =======#
  #=============================================#
  echo -e "\tAdding ingress controller -- ***start***"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.0/deploy/static/provider/cloud/deploy.yaml
  echo -e "\tAdding ingress controller -- ***done***"
  #=============================================#
  #========= Patch Public IP DNS Label =========
  #=============================================#    
  echo "Querying Public IP Resource Id for AKS Cluster. [Resource Group: $nodePoolRg]"
  retries=0
  while [[ $retries -lt 5 ]]; do
    publicIpResourceId=$(az network public-ip list --resource-group $nodePoolRg --query "[?contains(name, 'kubernetes')].id" -otsv)
    if [[ -z ${publicIpResourceId} ]]; then
      echo "Could not fetch Public IP Resource Id. Retrying..."
      retries=$((retries+1))
    else
      break
    fi
  done

  if [[ $retries -eq 5 ]]; then
    echo "Could not fetch Public IP Resource Id after 5 attempts. Exiting"
    exit 1
  fi

  echo "Found Public Ip ResourceId: $publicIpResourceId. Updating DNS Label to ${resourcesPrefix}"
  az network public-ip update --ids $publicIpResourceId --dns-name ${resourcesPrefix}
  echo "Public IP DNS Label has been updated to ${resourcesPrefix}"

  #=============================================#
  #======== Create Connected-ARC Cluster =======#
  #=============================================#
  echo -e "\tConnecting AKS to ARC-AKS -- ***start***"
  az connectedk8s connect --name ${connectedClusterName} --resource-group $rg --yes
  echo "Performing AKS-Arc-connected connectivity Sanity test"
  connectedResult=$(az connectedk8s show --name ${connectedClusterName} --resource-group $rg 2>&1)
  if [[ "$connectedResult" == *"ERROR"* ]]; then
    echo "AKS-Arc-connected connectivity Sanity test failed. Exiting"
    exit 1
  fi
  echo -e "\tconnecting AKS to ARC-AKS -- ***done***"
fi

#===========================================================================================================#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Deploy Video Indexer Extension @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#===========================================================================================================#
if [[ $install_extension == "true" ]]; then
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
  echo "Installing VI Extenion into AKS Connected Cluster ${connectedClusterName} on ResourceGroup $rg"
  echo "==============================="
  ######################
  ENDPOINT_URI=$(az network public-ip list --resource-group $nodePoolRg --query "[?contains(name, 'kubernetes')].dnsSettings.fqdn" -otsv)
  echo "Check If ${extensionName} extension is already installed"
  exists=$(az k8s-extension list --cluster-name ${connectedClusterName} --cluster-type connectedClusters -g $rg --query "[?extensionType=='microsoft.videoindexer'].name" -otsv)
  
  if [[ ! -z $exists ]]; then
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
                          --config "videoIndexer.endpointUri=https://${ENDPOINT_URI}"
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
                              --config "videoIndexer.endpointUri=https://${ENDPOINT_URI}" \
                              --config "storage.storageClass=azurefile-csi" \
                              --config "storage.accessMode=ReadWriteMany" 
    echo -e "\tCreate New VI Extension - ***done***"
  fi
fi  

echo "==============================="
echo "VI Extension is installed"
echo "==============================="
