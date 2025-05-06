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
| `create camera`     | Create a camera with optional preset                    | Use `-aio` flag to create with AIO resources |
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

| Option                         | Description                                     | Notes |
| ----------------------------- | ----------------------------------------------- | ----- |
| `-y`, `--yes`                | Skip confirmation prompts                       | Useful for automated scripts |
| `-h`, `--help`               | Show command help and examples                  | Displays detailed usage information |
| `-it`, `--interactive`       | Enable interactive parameter input              | Prompts for required parameters |
| `-aio`, `--aio-enabled`      | Enable Azure IoT Operations integration         | Creates required AIO resources |
| `-live`, `--live-enabled`    | Enable live stream capability                   | Used with upgrade extension |
| `-media`, `--media-enabled`  | Enable media files capability                   | Used with upgrade extension |
| `--clusterName`              | Name of the cluster                             | Required for most commands |
| `--clusterResourceGroup`     | Resource group of the cluster                   | Required for most commands |
| `--accountName`              | Name of the Video Indexer account               | Required for most commands |
| `--accountResourceGroup`     | Resource group of the Video Indexer account     | Required for most commands |
| `--cameraName`               | Name of the camera                              | Required for camera creation |
| `--cameraAddress`            | RTSP address of the camera                      | Required for non-AIO cameras |
| `--presetName`               | Name of the preset                              | Optional for camera creation |
| `--presetId`                 | ID of the preset                                | Required for preset deletion |
| `--cameraId`                 | ID of the camera                                | Required for camera deletion |
| `--cameraUsername`           | Username for camera authentication              | Optional, used with AIO |
| `--cameraPassword`           | Password for camera authentication              | Optional, used with AIO |

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

### Download the vi cli script
```bash
curl -fsSL -o vi_cli.sh https://raw.githubusercontent.com/Azure-Samples/azure-video-indexer-samples/refs/heads/live-private-preview/VideoIndexerEnabledByArc/live/vi_cli.sh

chmod +x ./vi_cli.sh

./vi_cli.sh -h
```

### Check Dependencies
For the first time using the script, please run this command:

```bash
./vi_cli.sh check dependencies
```

### Update Azure Arc Video Indexer Extension using CLI

To **update** Azure Arc Video Indexer Extension using CLI, continue here:  
As mentioned above, Video Indexer has two modes: **Media Files Enabled** and **Live Enabled** solution.  
This section will help you to enable/disable between modes.  
To get your current extension settings, run this command:

```bash
./vi_cli.sh show extension -it
```

Run this command to toggle between modes, for example, to enable both **Media Files** and **Live** solutions:

```bash
./vi_cli.sh upgrade extension \
--clusterName "my-connected-cluster" \
--clusterResourceGroup "my-connected-cluster" \
--accountName "my-connected-cluster" \
--accountResourceGroup "my-connected-cluster" \
--live-enabled \
--media-enabled
```

Or if you prefer the interactive mode:

```bash
./vi_cli.sh upgrade extension -it
```

### Connecting cameras to VI With AIO disabled

Create a camera and preset with arguments:

```bash
./vi_cli.sh create camera -y \
--cameraName "my camera" \
--cameraAddress "rtsp://my-ip-camera:8554/my-stream" \
--presetName "my preset" \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

Create a camera in interactive mode:

```bash
./vi_cli.sh create camera -it
```

### Deleting cameras from VI with AIO disabled

Delete a camera with arguments:

```bash
./vi_cli.sh delete camera -y \
--cameraId "my camera id" \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

Delete a camera in interactive mode:

```bash
./vi_cli.sh delete camera -it
```

### Connecting cameras to VI with AIO enabled

When connecting cameras with AIO integration, there are two main components:

1. **Asset Endpoint Profile**: Defines the connection to your camera including:
   - Target RTSP address
   - Authentication method (Anonymous or Username/Password)
   - Additional configuration settings

2. **Asset**: Configures how to handle the camera connection including:
   - Stream processing configuration
   - Media server integration
   - Data point settings for the stream

To create a camera with AIO integration (creates all components):

```bash
./vi_cli.sh create camera -aio -y \
--cameraName "my camera" \
--cameraAddress "rtsp://my-ip-camera:8554/my-stream" \
--presetName "my preset" \
--cameraUsername "optional-username" \
--cameraPassword "optional-password" \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

This command will create the following: 
1. Asset endpoint profile (AIO)
2. Asset (AIO)
3. Preset (VI)
4. Camera (VI)

Or in interactive mode:

```bash
./vi_cli.sh create camera -aio -it
```

### Deleting cameras from VI with AIO enabled

To delete a camera and all associated AIO resources:

```bash
./vi_cli.sh delete camera -aio -y \
--cameraId "my camera id" \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

Or in interactive mode:

```bash
./vi_cli.sh delete camera -aio -it
```

This command will delete the following: 
1. Asset endpoint profile (AIO)
2. Asset (AIO)
3. Camera (VI)

### Additional Commands

Show all configured cameras:
```bash
./vi_cli.sh show cameras -y \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

List available presets:
```bash
./vi_cli.sh show presets -y \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

Display current access token:
```bash
./vi_cli.sh show token -y \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

Show extension details:
```bash
./vi_cli.sh show extension -y \
--clusterName "my-cluster-name" \
--clusterResourceGroup "my-cluster-resource-group" \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
```

Display account information:
```bash
./vi_cli.sh show account -y \
--accountName "my-account-name" \
--accountResourceGroup "my-account-resource-group"
