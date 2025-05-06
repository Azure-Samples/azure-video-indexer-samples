# Video Indexer Live Enabled Arc Extension
# Private Preview Only!

## About

Video Indexer supports two modes: **Media Files Enabled** and **Live Enabled** solution. The Live Enabled solution is an Azure Arc Extension Enabled Service aimed at running live Video Analysis on Edge Devices. The solution is designed to run on Azure Arc-enabled Kubernetes and supports many camera vendors. The solution assumes that one VI resource is mapped to one extension.

The purpose of this document is to present the onboarding steps and pre-requisites required for Cluster Administrator, IT Operator, Dev Ops and Engineering teams to enable Video Indexer Live Enabled as arc extension on their current Infrastructure.

## Prerequisites

If you don't already have the **Video Indexer Arc Extension**, please follow [Video Indexer Arc Extension](https://github.com/Azure-Samples/azure-video-indexer-samples/tree/master/VideoIndexerEnabledByArc/aks#video-indexer-arc-extension). 

If you already have the **Video Indexer Arc Extension**, then continue with this guide.  
The Video Indexer Live Enabled can work with or without **Azure IoT Operations** (AIO) extension.   
Learn more here: [Deploy Azure IoT Operations to an Arc-enabled Kubernetes cluster](https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-deploy-iot-operations) 


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

### Step 1 - Download the vi cli script
```bash
wget -SSL https://raw.githubusercontent.com/Azure-Samples/azure-video-indexer-samples/refs/heads/live-private-preview/VideoIndexerEnabledByArc/live/vi_cli.sh

chmod +x ./vi_cli.sh

./vi_cli.sh -h
```

### Step 2 - Update Azure Arc Video Indexer Extension using CLI

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

### Connecting cameras to VI

#### With AIO disabled

Create a camera

```bash
 ./vi_cli.sh create camera -it
```

Create a camera and preset.

```bash
 ./vi_cli.sh create camera -preset -it
```

#### Deleting cameras

Delete a camera and preset.

```bash
 ./vi_cli.sh delete camera -preset -it
```

#### With AIO enabled

Connecting cameras to AIO requires two main keypoints: asset endpoint profiles and assets.  
**assets endpoint profile**: is the connection definition to your camera. 
**asset**: is what to do with this connection.

```bash
 ./vi_cli.sh create camera -aio -preset -it
```

This command will create the following: 
1. asset endpoint profile (AIO)
2. asset (AIO)
3. preset (VI)
4. camera (VI)

The assets are created in AIO, while the preset and camera will be created in Video Indexer.

#### Deleting cameras
```bash
 ./vi_cli.sh delete camera -aio -preset -it
```

This command will delete the following: 
1. asset endpoint profile (AIO)
2. asset (AIO)
3. preset (VI)
4. camera (VI)