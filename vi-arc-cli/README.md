# Video Indexer Arc CLI

A modern command-line interface for deploying Azure Video Indexer Arc on Kubernetes clusters (AKS or any Kubernetes cluster).

![Node.js](https://img.shields.io/badge/Node.js-18+-green)
![License](https://img.shields.io/badge/License-MIT-blue)

## ✨ Features

- 🚀 **Full AKS Cluster Setup** - Create and configure Azure Kubernetes Service clusters
- 🔗 **Generic Kubernetes Support** - Connect any existing Kubernetes cluster (Azure Local, on-prem, etc.)
- 🤖 **Auto-Detection** - Automatically detects Azure subscription, Video Indexer accounts, and configuration
- 📊 **Modern UI** - Beautiful CLI with progress indicators, spinners, and colored output
- 🎛️ **Interactive Setup** - Step-by-step wizard for easy configuration
- 🔄 **Resumable** - Resume deployments from where they left off
- 📹 **API Integration** - Manage cameras, presets, and insights directly from CLI

## 📋 Prerequisites

Before using this CLI, ensure you have the following installed:

| Tool | Version | Installation |
|------|---------|--------------|
| Node.js | 18.0+ | [nodejs.org](https://nodejs.org/) |
| Azure CLI | Latest | [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) |
| kubectl | Latest | [Install kubectl](https://kubernetes.io/docs/tasks/tools/) |
| Helm | 3.x | [Install Helm](https://helm.sh/docs/intro/install/) |

## 🚀 Installation

### Option 1: Install globally from npm (recommended)

```bash
npm install -g vi-arc-cli
```

### Option 2: Install from source

```bash
# Clone the repository
git clone https://github.com/Azure-Samples/azure-video-indexer-samples.git
cd azure-video-indexer-samples/vi-arc-cli

# Install dependencies
npm install

# Link globally
npm link
```

### Option 3: Run without installation

```bash
npx vi-arc-cli
```

## 🎯 Quick Start

### For New AKS Clusters

```bash
# 1. Run the interactive setup wizard
vi-arc setup

# 2. Deploy the full cluster (takes ~20-30 minutes)
vi-arc cluster deploy

# 3. Install the Video Indexer extension
vi-arc extension install
```

### For Existing Kubernetes Clusters

```bash
# 1. Initialize for your existing cluster
vi-arc k8s init

# 2. Deploy Video Indexer components
vi-arc k8s deploy

# 3. Install the Video Indexer extension
vi-arc extension install
```

## 📖 Commands

### Setup & Configuration

| Command | Description |
|---------|-------------|
| `vi-arc setup` | Interactive setup wizard |
| `vi-arc setup --reset` | Reset and reconfigure |
| `vi-arc config show` | Display current configuration |
| `vi-arc config set <key> <value>` | Set configuration value |
| `vi-arc config edit` | Interactive configuration editor |
| `vi-arc status` | Show deployment status |

### AKS Cluster Management

| Command | Description |
|---------|-------------|
| `vi-arc cluster create` | Create new AKS cluster |
| `vi-arc cluster deploy` | Full automated deployment |
| `vi-arc cluster nodepools` | Add node pools |
| `vi-arc cluster gpu-operator` | Install NVIDIA GPU operator |
| `vi-arc cluster ingress` | Configure ingress controller |
| `vi-arc cluster arc-connect` | Connect to Azure Arc |
| `vi-arc cluster cert-manager` | Install cert manager |

### Generic Kubernetes (Non-AKS)

| Command | Description |
|---------|-------------|
| `vi-arc k8s init` | Initialize for existing cluster |
| `vi-arc k8s deploy` | Deploy on existing cluster |
| `vi-arc k8s verify` | Verify cluster requirements |
| `vi-arc k8s gpu-operator` | Install GPU operator |
| `vi-arc k8s arc-connect` | Connect to Azure Arc |
| `vi-arc k8s cert-manager` | Install cert manager |

### Video Indexer Extension

| Command | Description |
|---------|-------------|
| `vi-arc extension install` | Deploy VI extension |
| `vi-arc extension update` | Update extension |
| `vi-arc extension delete` | Remove extension |
| `vi-arc extension status` | Show extension status |
| `vi-arc extension show-config` | Show extension configuration |

### Video Indexer API

| Command | Description |
|---------|-------------|
| `vi-arc api auth --token <token>` | Set API authentication |
| `vi-arc api camera list` | List cameras |
| `vi-arc api camera add` | Add a camera |
| `vi-arc api camera get <id>` | Get camera details |
| `vi-arc api camera delete <id>` | Delete camera |
| `vi-arc api preset list` | List presets |
| `vi-arc api preset create` | Create preset |
| `vi-arc api insight list` | List custom insights |
| `vi-arc api insight create` | Create custom insight |
| `vi-arc api video list` | List videos |
| `vi-arc api video search <query>` | Search videos |
| `vi-arc api tag list` | List tags |
| `vi-arc api tag create <key> <value>` | Create tag |

### Cleanup

| Command | Description |
|---------|-------------|
| `vi-arc cleanup` | Delete all resources |
| `vi-arc cleanup --extension-only` | Delete only extension |
| `vi-arc cleanup --keep-rg` | Keep resource group |
| `vi-arc cleanup extension` | Delete extension only |
| `vi-arc cleanup arc` | Disconnect from Arc |

## 🔧 Configuration

Configuration is stored locally and persists between sessions. Key configuration options:

### Required for Setup

| Key | Description |
|-----|-------------|
| `subscriptionId` | Azure subscription ID |
| `region` | Azure region (e.g., eastus, westeurope) |
| `resourcesPrefix` | Naming prefix for resources |

### Video Indexer Extension

| Key | Description |
|-----|-------------|
| `viAccountId` | Video Indexer account ID (GUID) |
| `viAccountResourceId` | Full ARM resource ID |
| `viExtensionVersion` | Extension version (e.g., 1.2.53) |
| `viEndpointUri` | Public endpoint URI |

### Feature Flags

| Key | Description | Default |
|-----|-------------|---------|
| `viLiveVideoEnabled` | Enable live video | true |
| `viMediaUploadsEnabled` | Enable media uploads | true |
| `viGpuSummarization` | Enable GPU summarization | false |

## 📁 Project Structure

```
vi-arc-cli/
├── src/
│   ├── index.js           # Main entry point
│   ├── commands/
│   │   ├── setup.js       # Setup wizard
│   │   ├── cluster.js     # AKS cluster management
│   │   ├── k8s.js         # Generic K8s support
│   │   ├── extension.js   # VI extension management
│   │   ├── api.js         # API operations
│   │   ├── config.js      # Configuration management
│   │   ├── status.js      # Status display
│   │   └── cleanup.js     # Resource cleanup
│   └── utils/
│       ├── exec.js        # Command execution
│       ├── azure.js       # Azure CLI helpers
│       ├── config.js      # Config management
│       └── api-client.js  # VI API client
├── package.json
└── README.md
```

## 🖥️ Supported Environments

### AKS (Managed)
- Full automated cluster creation
- Managed node pools with autoscaling
- Azure-native integrations

### Azure Local (HCI)
- Connect existing HCI clusters
- GPU operator installation
- Arc-enabled Kubernetes

### On-Premises / Other
- Any Kubernetes cluster 1.25+
- NVIDIA GPU support required
- Network connectivity to Azure

## 📊 GPU Requirements

Video Indexer Arc requires GPU nodes for live video processing. Supported GPU types:

| GPU | VM Size | Use Case |
|-----|---------|----------|
| H100 | Standard_NC40ads_H100_v5 | Best performance |
| A100 | Standard_NC24ads_A100_v4 | High performance |
| A10 | Standard_NV36ads_A10_v5 | Cost-effective |

### Check GPU Quota

```bash
# During setup, the CLI checks your GPU quota automatically
# Or check manually:
az vm list-usage --location eastus -o table | grep -i H100
```

## 🔒 Security

- All Azure operations use Azure CLI authentication
- API tokens are stored locally in your user config
- No credentials are transmitted to third parties
- Supports Azure Managed Identity

## 🐛 Troubleshooting

### Common Issues

**Azure CLI not logged in**
```bash
az login
```

**kubectl not configured**
```bash
az aks get-credentials --resource-group <rg> --name <cluster>
```

**Extension not installing**
```bash
vi-arc extension status
kubectl get pods -n video-indexer
```

**GPU nodes not scaling**
```bash
kubectl get pods -n gpu-operator
az aks nodepool show -g <rg> --cluster-name <cluster> -n gpudeepstrm
```

### Get Help

```bash
# Show help for any command
vi-arc --help
vi-arc cluster --help
vi-arc cluster create --help
```

## 📚 Additional Resources

- [Video Indexer Documentation](https://docs.microsoft.com/azure/azure-video-indexer/)
- [Azure Kubernetes Service](https://docs.microsoft.com/azure/aks/)
- [Azure Arc-enabled Kubernetes](https://docs.microsoft.com/azure/azure-arc/kubernetes/)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](../CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

**Made with ❤️ for the Azure Video Indexer community**
