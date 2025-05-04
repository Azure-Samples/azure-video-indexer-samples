# Video Indexer Live Enabled Arc Extension 

## About

Video Indexer supports two modes: **Media Files Enabled** and **Live Enabled** solution. The Live Enabled solution is an Azure Arc Extension Enabled Service aimed at running live Video Analysis on Edge Devices. The solution is designed to run on Azure Arc-enabled Kubernetes and supports many camera vendors. The solution assumes that one VI resource is mapped to one extension.

The purpose of this document is to present the onboarding steps and pre-requisites required for Cluster Administrator, IT Operator, Dev Ops and Engineering teams to enable Video Indexer Live Enabled as arc extension on their current Infrastructure.

## Prerequisites

If you don't already have the **Video Indexer Arc Extension**, please follow [Video Indexer Arc Extension](https://github.com/Azure-Samples/azure-video-indexer-samples/tree/master/VideoIndexerEnabledByArc/aks#video-indexer-arc-extension). 

If you already have the **Video Indexer Arc Extension**, then continue with this guide.  
The Video Indexer Live Enabled requires **Azure IoT Operations** (AIO) extension to be installed, you can follow this guide [Deploy Azure IoT Operations to an Arc-enabled Kubernetes cluster](https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-deploy-iot-operations) and return to this point once complete.  


## 1. Manual deployment steps start here

Follow these steps to deploy the Video Indexer Live Enabled Arc Extension to your Arc K8S Enabled cluster. 

### Minimum Software Requirements

| Component |  Minimum Requirements
| --- | ---
| Operating System | Ubuntu 22.04 LTS or any Linux Compatible OS
| Kubernetes | > 1.29
| Azure CLI | > 2.64.0

## Installation Steps

### Step 2 - Create Azure Arc Video Indexer Extension using CLI

```bash
wget -SSL https://raw.githubusercontent.com/Azure-Samples/media-services-video-indexer/master/VideoIndexerEnabledByArc/live/vi_extension_install.sh

chmod +x ./vi_extension_install.sh

sh vi_extension_install.sh
```

As mentioned above, Video Indexer has two modes: **Media Files Enabled** and **Live Enabled** solution.  
This section will help you to enable/disable between modes.  
To get your current extension settings, run this command:

```bash
 ./aio_vi_cli.sh show extension
```

Run this command to toggle between modes, for example, to enable both **Media Files** and **Live** solutions, we will set liveStreamEnabled and mediaFilesEnabled equals true.

```bash
 ./aio_vi_cli.sh upgrade extension
```


### Step 3 (Alternative) - Deploy Using Bicep Template

In case you do not wish to use Az CLI Commands to deploy the video indexer arc extension , you can use the bicep deployment
provided on the current folder.
> **_Note:_**: This Step replaces the need to run Step 2 + 3 above
> **_Note:_**: In order to deploy the Bicep template you will need to use user-assigned Managed Identity with a 'Contributor' Role Assignment on the Subscription.

1. Open The [Template File](vi.arcextension.template.bicep) file and Fill in the required parameters (see below).
2. Run the Following Az CLi Commands in order to deploy the template using the [az deployment group create](https://learn.microsoft.com/en-us/cli/azure/deployment/group?view=azure-cli-latest#az-deployment-group-create) command.

```shell
az deployment group create --resource-group myResourceGroup --template-file .\vi.arcextension.template.bicep
```

### Step 4 - Verify Deployment

```bash
kubectl get pods -n video-indexer
```

you will see the video indexer pods are up and running.

> **_Note_:** It might take few minutes for all the pods to become available and running .

# How To Access the extension :
**_Note_:** Please make sure your end of line sequence is LF and not CRLF for the script to work right away.
```bash
 ./aio_vi_cli.sh 
```


### Step 5 - Connecting cameras to AIO

Connecting cameras to AIO requires two main keypoints: asset endpoint profiles and assets.  
**assets endpoint profile**: is the connection definition to your camera. 
[asset-endpoint-profiles](https://learn.microsoft.com/en-us/rest/api/deviceregistry/asset-endpoint-profiles/create-or-replace?view=rest-deviceregistry-2024-11-01&tabs=HTTP)

**asset**: is what to do with this connection.
[assets](https://learn.microsoft.com/en-us/rest/api/deviceregistry/assets/create-or-replace?view=rest-deviceregistry-2024-11-01&tabs=HTTP)

Creating asset endpoint profiles and assets can be done from the [aio dashboard](https://iotoperations.azure.com/sites) or by using the `az cli`. This guide will show how to use the `az cli`.


#### Creating camera without AIO

```bash
 ./aio_vi_cli.sh create camera_vi
```

This command will create the following: 
1. preset (VI)
2. camera (VI)

The preset and camera will be created in Video Indexer.  


#### Creating camera with AIO

```bash
 ./aio_vi_cli.sh create camera
```

This command will create the following: 
1. asset endpoint profile (AIO)
2. asset (AIO)
3. preset (VI)
4. camera (VI)

The assets are created in AIO, while the preset and camera will be created in Video Indexer.  

