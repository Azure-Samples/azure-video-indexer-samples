# Deploy Video Indexer Enabled by Arc to Single Node Kubernetes Cluster (Kubeadm)

## About

The purpose of this document is to present the onboarding steps and pre-requisites required for Cluster Administrator, IT Operator, Dev Ops and Engineering teams to enable Video Indexer as arc extension on their current local compute layer that is not based on Azure Kubenernets Clusters.

In this tutorial you will be deploying Video Indexer Enabled by Arc solution into "Vanila" kubernetes cluster with the following characteristics :

* Single Node "control-plane" VM running On Linux with 32 Cores and 128G memory ( configurable)
* Kubeadm based cluster

> **_Notes:_** Video Indexer Enabled by Arc can be deployed on *ANY* Kuberenets cluster whether On-Prem or Cloud based.

>  For more information on kubeadm configuration and options visit [k8s Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).


Once the cluster will be created you will SSH into the VM and interact with Azure CLI and Kubectl commands in order to onboard
Azure Video Indexer Enabled by arc solution.


## Prerequisites

>NOTE: In order to succesfully deploy the VI Extention it is **mandatory** that we approve your Azure subscription id in advance. Therefore you must first sign up using [this form](https://aka.ms/vi-register).

- Azure subscription with permissions to create Azure resources
- Azure Video Indexer Account. The quickest way is using the Azure Portal using this tutorial [Create Video Indexer account](https://learn.microsoft.com/azure/azure-video-indexer/create-account-portal#use-the-azure-portal-to-create-an-azure-video-indexer-account).

- Permission to create Virtual machines on Azure.


## 1. Create Kubeadm single node Cluster .

1. Opem the `deploy.sh` script and edit the following varaibles :

- prefix : a user prefix string to serve as identifier for this tutorial resources.

- controlPlaneNodeVmSize : The VM Size to be used as the control-plance single node Kubernetes cluster. consult your IT Admin 
in order to select the right VM Size according to your subscription quota allocations for the deployed regino.

- location : The location where your solution will be deployed.

**_HINT_** : In order to get a list of allowed location names under your subscription consider using the following snippet: 

```bash
    az account list-locations --query "[].name" -o tsv
```

2. Login to Azure

```bash
az login --used-device-code
az account set --subscription <Your_Subscription_ID>
```

3. Deploy the script by running the following commands : 

```bash
chmod +x ./deploy.sh
./deploy.sh
```
