#!/bin/bash

#################################################
echo "Deploying Single Node K8s Cluster based on Kubeadm"
# Reference : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
#################################################
# Variables
prefix="<add your prefix here>"
resourceGroupName="${prefix}-rg"
controlPlaneNodeVmSize="Standard_D32a_v4"
location="eastus"
################################b################

# create ssh key and use it as admin password for the VM
ssh-keygen -t rsa -b 4096 -f ./id_rsa -q -N ""
publicSshKey=$(cat ./id_rsa.pub)

echo "Creating Resource Group"
az group create --name ${resourceGroupName} --location $location

echo "deploy Bicep template"
az deployment group create \
  --name "bicep-deploy" \
  --resource-group ${resourceGroupName} \
  --template-file "./single-node.k8s.bicep" \
  --parameters \
    prefix=$prefix \
    controlPlaneNodeVmSize=$controlPlaneNodeVmSize \
    vmAdminPasswordOrKey="$publicSshKey"
