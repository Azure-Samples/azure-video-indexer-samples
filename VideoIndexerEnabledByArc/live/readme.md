# Video Indexer Live Enabled Arc Extension
# Private Preview Only!

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


## Working with Live CLI

The `vi_cli.sh` script provides a comprehensive set of commands for managing Video Indexer and AIO resources. The script includes automatic prerequisites validation, error handling, and colored logging for better visibility.

### Available Commands

| Command             | Description                                             | Notes |
| ------------------- | ------------------------------------------------------- | ----- |
| `create camera`     | Create a camera with optional preset                    | Use `-aio` flag to create with AIO resources, `-preset` for preset creation |
| `create aep`        | Create asset endpoint profile                           | Creates connection definition for your camera in AIO |
| `create asset`      | Create asset in AIO                                     | Configures what to do with the camera connection |
| `create preset`     | Create a preset in Video Indexer                        | Configures insight types for video analysis |
| `delete camera`     | Delete a camera                                         | Also deletes associated AIO resources if `-aio` was used |
| `delete preset`     | Delete a preset                                         | Removes preset configuration from Video Indexer |
| `upgrade extension` | Upgrade Video Indexer extension                         | Can toggle between Media Files and Live Stream modes |
| `show cameras`      | List all configured cameras                            | Shows camera configurations and status |
| `show presets`      | List all available presets                             | Shows preset configurations |
| `show token`        | Show access token                                      | Displays current extension access token |
| `show extension`    | Show extension details                                 | Displays Video Indexer extension configuration |
| `show account`      | Show user account details                              | Displays Video Indexer account information |


### Command Options

| Option                 | Description                                     | Notes |
| ---------------------- | ----------------------------------------------- | ----- |
| `-y`, `--yes`          | Skip confirmation prompts                       | Useful for automated scripts |
| `-h`, `--help`         | Show command help and examples                 | Displays detailed usage information |
| `-s`, `--skip`         | Skip prerequisites validation                   | Skips checking dependencies, Azure CLI version, and extensions |
| `-it`, `--interactive` | Enable interactive parameter input             | Prompts for required parameters like camera name, credentials |
| `-aio`                | Enable Azure IoT Operations integration         | Creates required AIO resources along with VI resources |
| `-preset`             | Enable preset creation                         | Creates a preset with default insight types |

The script performs automatic validation of:
- Required dependencies (az, jq, curl)
- Azure CLI version (>= 2.64.0)
- Required Azure extensions
- Valid Azure login and tokens
- Resource provider registration

In interactive mode (`-it`), the script will prompt for:
- Cluster and resource group names
- Account configuration
- Camera details (name, RTSP URL)
- Authentication credentials (if using camera secrets)

**_Note_:** Please make sure your end of line sequence is LF and not CRLF for the script to work right away.

## Installation Steps

### Step 1 - Update Azure Arc Video Indexer Extension using CLI

To **create** Azure Arc Video Indexer Extension using CLI, see:
[](https://github.com/Azure-Samples/azure-video-indexer-samples/blob/master/VideoIndexerEnabledByArc/aks/readme.md#step-2---create-azure-arc-video-indexer-extension-using-cli)


To **update** Azure Arc Video Indexer Extension using CLI, continue here:
As mentioned above, Video Indexer has two modes: **Media Files Enabled** and **Live Enabled** solution.  
This section will help you to enable/disable between modes.  
To get your current extension settings, run this command:

```bash
 ./vi_cli.sh show extension -it
```

Run this command to toggle between modes, for example, to enable both **Media Files** and **Live** solutions, we will set liveStreamEnabled and mediaFilesEnabled equals true.

```bash
 ./vi_cli.sh upgrade extension -it
```

### Step 2 - Connecting cameras to VI

#### With AIO disabled

```bash
 ./vi_cli.sh create vi camera
```

This command will create the following: 
1. preset (VI)
2. camera (VI)

The preset and camera will be created in Video Indexer.


#### With AIO enabled
Connecting cameras to AIO requires two main keypoints: asset endpoint profiles and assets.  
**assets endpoint profile**: is the connection definition to your camera. 
[asset-endpoint-profiles](https://learn.microsoft.com/en-us/rest/api/deviceregistry/asset-endpoint-profiles/create-or-replace?view=rest-deviceregistry-2024-11-01&tabs=HTTP)

**asset**: is what to do with this connection.
[assets](https://learn.microsoft.com/en-us/rest/api/deviceregistry/assets/create-or-replace?view=rest-deviceregistry-2024-11-01&tabs=HTTP)

Creating asset endpoint profiles and assets can be done from the [aio dashboard](https://iotoperations.azure.com/sites) or by using the `vi_cli.sh`. This guide will show how to use the `vi_cli.sh`.

```bash
 ./vi_cli.sh create aio camera
```

This command will create the following: 
1. asset endpoint profile (AIO)
2. asset (AIO)
3. preset (VI)
4. camera (VI)

The assets are created in AIO, while the preset and camera will be created in Video Indexer.

### Example Usage with Error Handling

```bash
# Creating a camera with interactive mode and validation
./vi_cli.sh create camera -it -aio

# Creating a preset with skipped validation
./vi_cli.sh create preset -s -y
```
