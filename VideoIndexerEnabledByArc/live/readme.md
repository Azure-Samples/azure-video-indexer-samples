# Video Indexer Live Enabled Arc Extension
# Private Preview Only!

## Prerequisites

If you haven't installed the **Video Indexer Arc Extension** yet, please follow the [installation guide](https://github.com/Azure-Samples/azure-video-indexer-samples/blob/live-private-preview/VideoIndexerEnabledByArc/live/create_live_extension.md). 

Once you have installed the **Video Indexer Arc Extension**, you can continue with this guide.
Note that Video Indexer Live can operate with or without the **Azure IoT Operations** (AIO) extension.
To learn more about AIO, see: [Deploy Azure IoT Operations to an Arc-enabled Kubernetes cluster](https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-deploy-iot-operations) 


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

The `vi_cli.sh` script provides a comprehensive set of commands for managing Video Indexer and AIO resources. You can interact with the script in three different ways:

1. Interactive Mode (-it)
   - Guides you through parameter input
   - Prompts for required values
   - Best for beginners

2. Command-line Arguments
   - Specify all parameters in the command
   - Suitable for automation
   - Requires knowing parameter names

3. Environment Variables
   - Set common parameters once
   - Reduces command length
   - Available variables:
   ```bash
   export VI_CLUSTER_NAME=""
   export VI_CLUSTER_RESOURCE_GROUP=""
   export VI_ACCOUNT_NAME=""
   export VI_ACCOUNT_RESOURCE_GROUP=""
   ```

You can combine these approaches. For example:
```bash
export VI_CLUSTER_NAME="<cluster-name>"
./vi_cli.sh create camera --cameraName "<camera-name>" -it
```

### Available Commands

| Command             | Description                                             | Example Usage |
| ------------------- | ------------------------------------------------------- | ------------- |
| `check dependencies`| Validates and installs required tools                   | `./vi_cli.sh check dependencies` |
| `create camera`     | Creates a new camera with optional analysis preset      | `./vi_cli.sh create camera -it` |
| `create aep`        | Creates a camera connection profile (AIO only)          | `./vi_cli.sh create aep -y` (AIO only) |
| `create asset`      | Creates stream handling settings (AIO only)             | `./vi_cli.sh create asset -y` (AIO only) |
| `create preset`     | Creates an analysis preset for video processing         | `./vi_cli.sh create preset --presetName "<name>"` |
| `delete camera`     | Removes a camera and its associated resources           | `./vi_cli.sh delete camera -y --cameraId "<id>"` |
| `delete preset`     | Removes an analysis preset configuration                | `./vi_cli.sh delete preset -y --presetId "<id>"` |
| `upgrade extension` | Updates the extension configuration                     | `./vi_cli.sh upgrade extension -it` |
| `show cameras`      | Lists all registered cameras                           | `./vi_cli.sh show cameras -y` |
| `show presets`      | Lists all available analysis presets                   | `./vi_cli.sh show presets -y` |
| `show token`        | Retrieves current access token                         | `./vi_cli.sh show token -y` |
| `show extension`    | Displays current extension settings                    | `./vi_cli.sh show extension -it` |
| `show account`      | Shows Video Indexer account details                    | `./vi_cli.sh show account -it` |

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
| `--cameraDescription`        | Description of the camera                       | No |
| `--cameraStreamingEnabled`   | Enable streaming for the camera                 | No |
| `--cameraRecordingEnabled`   | Enable recording for the camera                 | No |
| `--cameraUsername`           | Username for camera authentication (AIO only)   | No |
| `--cameraPassword`           | Password for camera authentication (AIO only)   | No |

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

Upgrade current extension settings:
```bash
./vi_cli.sh upgrade extension -it
```
This interactive mode command will ask you to:  
Enable Live Stream? (true/false)  
Enable Media Files? (true/false)


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

### Managing Cameras Without AIO

#### Creating a Camera
There are two recommended ways to create a camera:

1. Using Interactive Mode
   ```bash
   ./vi_cli.sh create camera -it
   ```
   This is the simplest option - the script will guide you through entering all required parameters.

2. Using Pre-filled Parameters
   ```bash
   ./vi_cli.sh create camera --cameraName "<camera-name>" --clusterName "<cluster-name>"
   ```

#### Creating a Camera with Preset
To enable automatic video analysis on your camera:
Include the `--presetName` parameter when creating the camera.  
The script will automatically create a preset that detects:
   - People in the video stream
   - Vehicles in the video stream

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

#### Deleting a Camera

To delete a camera, follow these steps:

1. Find the Camera ID
   ```bash
   ./vi_cli.sh show cameras -y \
   --clusterName "<cluster-name>" \
   --clusterResourceGroup "<cluster-resource-group>" \
   --accountName "<account-name>" \
   --accountResourceGroup "<account-resource-group>"
   ```

2. Delete Using the Camera ID

```bash
./vi_cli.sh delete camera -y \
--cameraId "<camera-id>" \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

### Managing Cameras With AIO

When you enable AIO integration, the system creates and manages two additional components:

1. **Asset Endpoint Profile**: Defines the camera connection
   - Target RTSP address
   - Authentication method (Anonymous or Username/Password)
   - Additional configuration settings

2. **Asset**: Configures the camera stream handling
   - Stream processing settings
   - Media server integration
   - Data point configuration

#### Creating a Camera with AIO
Use the following command to create a camera with full AIO integration:
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

The command above performs these steps automatically:
1. Creates an Asset Endpoint Profile in AIO
2. Creates an Asset in AIO for stream management
3. Creates a Video Preset in Video Indexer
4. Creates a Camera in Video Indexer
5. Links all components together for seamless operation

#### Deleting a Camera with AIO Integration
To remove a camera and all its associated components:
```bash
./vi_cli.sh delete camera -aio -y \
--cameraId "<camera-id>" \
--clusterName "<cluster-name>" \
--clusterResourceGroup "<cluster-resource-group>" \
--accountName "<account-name>" \
--accountResourceGroup "<account-resource-group>"
```

This command removes:
1. The Asset Endpoint Profile from AIO
2. The Asset configuration from AIO
3. The Camera from Video Indexer

All components are deleted in the correct order to ensure clean removal.

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
