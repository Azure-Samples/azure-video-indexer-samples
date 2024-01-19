
echo "Part 1: Deploying Single Node K8s Cluster based on Kubeadm"
# Reference : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

#################################################
# Variables
prefix="tsk8s"
controlPlaneNodeVmSize="Standard_D32a_v4"
location="eastus"
################################################

# create dummy ssh key and use it as password
ssh-keygen -t rsa -b 4096 -f ./id_rsa -q -N ""
publicSshKey=$(cat ./id_rsa.pub)
vaultName="${prefix}-kv"

rgName="${prefix}-rg"


username=$(az account show  --query user.name -otsv)
userPrincipalId=$(az ad user show --id $username --query id -otsv)
echo "found userPrincipalId: $userPrincipalId"

echo "Creating Resource Group"
az group create --name $rgName --location $location

echo "deploy Bicep template"
az deployment group create \
  --name "bicep-deploy" \
  --resource-group $rgName \
  --template-file "./single-node.k8s.bicep" \
  --parameters \
    prefix=$prefix \
    userPrincipalId=$userPrincipalId \
    controlPlaneNodeVmSize=$controlPlaneNodeVmSize \
    vmAdminPasswordOrKey="$publicSshKey"

#echo "Part 2: Deploying Video Indexer Enabled by Arc extension to the AKS "