#!/bin/bash

echo "VM Installation script for Kubeadm , Azure CLI and other configuration needed for Arc-Enabled"

#  install tools
sudo apt-install update & sudo apt-install jq vim yq -y

##  install kubeadm
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  

## install Azure CLI
curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_master.sh | sudo bash

# remove node taints for control plane node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Install Azure CLI extensions
# https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli
az extension add --name connectedk8s
az extension add --name aks-preview
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation

echo "VM Post Installation script for Kubeadm , completed. ./install_extension.sh to install video indexer extension"

