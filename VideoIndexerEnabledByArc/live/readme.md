# Video Indexer Live Enabled Arc Extension
# Private Preview Only!

## Prerequisites

If you don't already have the **Video Indexer Arc Extension**, please follow [Video Indexer Arc Extension](https://github.com/Azure-Samples/azure-video-indexer-samples/blob/live-private-preview/VideoIndexerEnabledByArc/live/create_live_extension.md). 

If you already have the **Video Indexer Arc Extension**, then continue with this guide.  
The Video Indexer Live Enabled can work with or without **Azure IoT Operations** (AIO) extension.   
Learn more here: [Deploy Azure IoT Operations to an Arc-enabled Kubernetes cluster](https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-deploy-iot-operations) 


## Download and Setup

```bash
# Download the script
curl -fsSL -o vi_cli.sh https://raw.githubusercontent.com/Azure-Samples/azure-video-indexer-samples/refs/heads/live-private-preview/VideoIndexerEnabledByArc/live/vi_cli.sh

# Make it executable
chmod +x ./vi_cli.sh

# View help
./vi_cli.sh -h

# For the first time using the script, please run this command:
./vi_cli.sh check dependencies
```

## Working with Live CLI

The `vi_cli.sh` script provides a comprehensive set of commands for managing Video Indexer and AIO resources.  
It supports three operation modes: interactive (-it), command-line arguments, and environment variables.  
The supported environment variables include:
```bash
export VI_CLUSTER_NAME=""
export VI_CLUSTER_RESOURCE_GROUP=""
export VI_ACCOUNT_NAME=""
export VI_ACCOUNT_RESOURCE_GROUP=""
```

This is an easy way to set the environment variables just once.

These modes can be used together. For example:
```bash
export VI_CLUSTER_NAME="<cluster-name>"
./vi_cli.sh create camera --cameraName "<camera-name>" -it
```

### Available Commands

| Command             | Description                                             | Notes |
| ------------------- | ------------------------------------------------------- | ----- |
| `check dependencies`| Check and install required dependencies                 | Validates az CLI, jq, curl installation |
| `create camera`     | Create a camera with optional preset                    | Use `-aio` flag to create with AIO resources |
| `create aep`        | Create asset endpoint profile                           | Creates connection definition for your camera in AIO |
| `create asset`      | Create asset in AIO                                     | Configures what to do with the camera connection |
| `create preset`     | Create a preset in Video Indexer                        | Configures insight types for video analysis |
| `delete camera`     | Delete a camera and associated resources                | Also deletes associated AIO resources if `-aio` was used |
| `delete preset`     | Delete a preset                                         | Removes preset configuration from Video Indexer |
| `upgrade extension` | Upgrade Video Indexer extension                         | Can toggle between Media Files and Live Stream modes |
| `show cameras`      | List all configured cameras                            | Shows camera configurations and status |
| `show presets`      | List all available presets                             | Shows preset configurations |
| `show token`        | Show access token                                      | Displays current extension access token |
| `show extension`    | Show extension details                                 | Displays Video Indexer extension configuration |
| `show account`      | Show user account details                              | Displays Video Indexer account information |

### Command Options

| Option                         | Description                                     | Required |
| ----------------------------- | ----------------------------------------------- | -------- |
| `-y`, `--yes`                | Skip confirmation prompts                       | No |
| `-h`, `--help`               | Show command help and examples                  | No |
| `-it`, `--interactive`       | Enable interactive parameter input              | No |
| `-aio`, `--aio-enabled`      | Enable Azure IoT Operations integration         | No |
| `-live`, `--live-enabled`    | Enable live stream capability                   | No |
| `-media`, `--media-enabled`  | Enable media files capability                   | No |
| `--clusterName`              | Name of the cluster                             | Yes* |
| `--clusterResourceGroup`     | Resource group of the cluster                   | Yes* |
| `--accountName`              | Name of the Video Indexer account               | Yes* |
| `--accountResourceGroup`     | Resource group of the Video Indexer account     | Yes* |
| `--cameraName`               | Name of the camera                              | Yes* |
| `--cameraAddress`            | RTSP address of the camera                      | Yes* |
| `--presetName`               | Name of the preset                              | No |
| `--presetId`                 | ID of the preset                                | Yes* |
| `--cameraId`                 | ID of the camera                                | Yes* |
| `--cameraUsername`           | Username for camera authentication              | No |
| `--cameraPassword`           | Password for camera authentication              | No |

\* Required for most commands unless using interactive mode (-it)  

**Note:** Use the `-it` flag with any command to enter interactive mode, which will prompt for required parameters.

### Prerequisites Validation

The script automatically validates:
- Required dependencies (az, jq, curl)
- Azure CLI version (>= 2.64.0)
- Required Azure CLI extensions (azure-iot-ops, connectedk8s, k8s-extension, customlocation)
- Valid Azure login and tokens
- Azure resource provider registration

### Managing the Video Indexer Extension

Show current extension settings:
```bash
./vi_cli.sh show extension -it
```

Update extension settings (enable both Media Files and Live modes):
```bash
./vi_cli.sh upgrade extension \
--clusterName "<your-cluster-name>" \
--clusterResourceGroup "<your-cluster-resource-group>" \
--accountName "<your-account-name>" \
--accountResourceGroup "<your-account-resource-group>" \
--live-enabled \
--media-enabled
```

Or use interactive mode:
```bash
./vi_cli.sh upgrade extension -it
```

### Managing Cameras Without AIO

The most basic command to start with is by just using the interactive mode.
```bash
./vi_cli.sh create camera -it
```

Another option is to prefill all know parameters but keep the interactive mode:
```bash
./vi_cli.sh create camera --cameraName "<camera-name>" --clusterName "<cluster-name>" -it
```


Create a camera without interactive mode:
```bash
./vi_cli.sh create camera -y \
--cameraName "<camera-name>" \
--cameraAddress "<rtsp-camera-address>" \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

If you want to create camera and a preset connected to it, just pass the --presetName

```bash
./vi_cli.sh create camera -y \
--cameraName "<camera-name>" \
--cameraAddress "<rtsp-camera-address>" \
--presetName "<preset-name>" \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

Delete a camera:
```bash
./vi_cli.sh delete camera -y \
--cameraId "<camera-id>" \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

### Managing Cameras With AIO

When using AIO integration, the following components are created:

1. **Asset Endpoint Profile**: Defines the camera connection
   - Target RTSP address
   - Authentication method (Anonymous or Username/Password)
   - Additional configuration settings

2. **Asset**: Configures the camera stream handling
   - Stream processing settings
   - Media server integration
   - Data point configuration

Create a camera with AIO integration:
```bash
./vi_cli.sh create camera -aio -y \
--cameraName "<camera-name>" \
--cameraAddress "<rtsp-camera-address>" \
--presetName "<preset-name>" \
--cameraUsername "<optional-username>" \
--cameraPassword "<optional-password>" \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

This creates:
1. Asset endpoint profile (AIO)
2. Asset (AIO)
3. Preset (VI)
4. Camera (VI)

Delete a camera with AIO integration:
```bash
./vi_cli.sh delete camera -aio -y \
--cameraId "<camera-id>" \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

This deletes:
1. Asset endpoint profile (AIO)
2. Asset (AIO)
3. Camera (VI)

### Additional Commands

List all cameras:
```bash
./vi_cli.sh show cameras -y \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

List presets:
```bash
./vi_cli.sh show presets -y \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

Show access token:
```bash
./vi_cli.sh show token -y \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

Show account info:
```bash
./vi_cli.sh show account -y \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```
