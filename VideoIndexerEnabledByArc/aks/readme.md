# Video Indexer Arc Extension

## About

Video Indexer Arc Enabled Solution is an Azure Arc Extension Enabled Service aimed at running Video and Audio Analysis on Edge Devices. The solution is designed to run on Azure Stack Edge Profile, a heavy edge device, and supports three video formats, including MP4 and four additional common formats. The solution supports three Azure languages (English, German, Spanish) in all basic audio-related models and assumes that one VI resource is mapped to one extension.

The purpose of this document is to present the onboarding steps and pre-requisites required for Cluster Administrator, IT Operator, Dev Ops and Engineering teams to enable Video Indexer as arc extension on their current Infrastructure.

## Prerequisites


> **_Note_:** In order to succesfully deploy the VI Extention it is **mandatory** that we approve your Azure subscription id in advance. Therefore you must first sign up using [this form](https://aka.ms/vi-register).


- Azure subscription with permissions to create Azure resources
- Azure Video Indexer Account. The quickest way is using the Azure Portal using this tutorial [Create Video Indexer account](https://learn.microsoft.com/azure/azure-video-indexer/create-account-portal#use-the-azure-portal-to-create-an-azure-video-indexer-account).
- The AKS cluster that will contain the Video Indexer extension must be in the East US region.
- The latest version of [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli). (**You can skip if you're using the Cloud Shell**).
- The latest version of connectedk8s Azure CLI extension, installed by running the following command. (**You can skip if you're using the Cloud Shell**):

```bash
az extension add --name connectedk8s
az provider register -n 'Microsoft.Kubernetes' 
az provider register -n 'Microsoft.KubernetesConfiguration' 
az provider register -n 'Microsoft.ExtendedLocation'
```


## 1. One-Click Deploy Sample to Azure
**This step is optional.** If you would like to test Video Indexer Edge Extention on a sample edge device this deployment script can be used to quickly set up a K8S cluster and all pods to run VI on Edge. This script will deploy the following resources:
- Small 2 node AKS Cluster (costs are ~$0.80/hour)
- Enable ARC Extension on top of the cluster
- Add Video Indexer Arc Extension
- Add Video Indexer and Cognitive Services Speech + Translation containers
- Expose the Video Indexer Swagger API for dataplane operations

You can read more on how to set up your cloud shell environment [here](https://learn.microsoft.com/azure/cloud-shell/quickstart?tabs=azurecli).

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://shell.azure.com/bash?url=)

In the cloud shell execute the following command:

```bash
wget -SSL https://raw.githubusercontent.com/Azure-Samples/media-services-video-indexer/master/VideoIndexerEnabledByArc/aks/vi_extension_install.sh -O vi_extension_install.sh

chmod +x ./vi_extension_install.sh

sh vi_extension_install.sh
```
> **_Note_:** The script aim to run on Ubuntu OS and contains command that uses Ubuntu package manager. 

During the deployment the script will ask the following questions where you will need to provide your environment specific values. Below table explains each question and the desired value. Some will expect or have default values.

| Question | value | Details
| --- | --- | --- |
| What is the Video Indexer account ID during deployment? | GUID | Your Video Indexer Account ID |
| What is the Azure subscription ID during deployment? | GUID | Your Azure Subscription ID |
| What is the name of the Video Indexer resource group during deployment? | string | The Resource Group Name of your Video Indexer Account |
| What is the name of the Video Indexer account during deployment? | string | Your Video Indexer Account name |


Once deployed you will get a URL to the Data Plane API of your new Video Indexer on Edge extension which is now running on the AKS cluster. You can use this API to perform indexing jobs and test Video Indexer on Edge. Please note that this is **not** meant as a path to production and only provided to quickly test Video Indexer on Edge functionality. This concludes the demo script and you are done. Below are the steps if you want to deploy VI on Edge manually.