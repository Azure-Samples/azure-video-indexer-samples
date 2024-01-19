# Deploy Video Indexer Enabled by Arc to Single Node Kubernetes Cluster (Kubeadm)

## About
This document provides the onboarding steps and prerequisites for Cluster Administrators, IT Operators, DevOps, and Engineering teams to enable Video Indexer as an Arc extension on their current local compute layer, not based on Azure Kubernetes Clusters.

In this tutorial, you will deploy Video Indexer Enabled by Arc into a "Vanilla" Kubernetes cluster with the following characteristics:

- Single Node "control-plane" VM running on Linux with 32 Cores and 128GB memory (configurable)
- Kubeadm based cluster

**Notes:** Video Indexer Enabled by Arc can be deployed on ANY Kubernetes cluster, whether On-Prem or Cloud-based. For more information on kubeadm configuration and options, visit [Kubernetes Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/).

Once the cluster is created, you will SSH into the VM and interact with Azure CLI and Kubectl commands to onboard Azure Video Indexer Enabled by Arc solution.

## Prerequisites
**NOTE:** To successfully deploy the VI Extension, it is mandatory to have your Azure subscription ID approved in advance. Sign up using [this form](link_to_form).

- Azure subscription with permissions to create Azure resources
- Azure Video Indexer Account. Follow [this tutorial](link_to_tutorial) to create a Video Indexer account.
- Permission to create Virtual machines on Azure.

## Deployment Steps 

1. **Create Kubeadm Single Node Cluster**

Open the `deploy.sh` script and edit the following variables:

- `prefix`: A user prefix string to serve as an identifier for this tutorial resources.
- `controlPlaneNodeVmSize`: The VM Size to be used as the control-plane single node Kubernetes cluster. Consult your IT Admin to select the right VM Size based on your subscription quota allocations for the deployed region.
- `location`: The location where your solution will be deployed.

**Hint:** To get a list of allowed location names under your subscription, consider using the following snippet:

```bash
az account list-locations --query "[].name" -o tsv
```

Login to Azure

```bash
az login --used-device-code
az account set --subscription <Your_Subscription_ID>
```

Deploy the script by running the following commands : 

```bash
chmod +x ./deploy.sh
./deploy.sh
```

2. **SSH into the Kubernetes control Plane node**

using the Azure Portal Connect to the VM created on previous step.
Use the SSH Keys created on previous step to connect to the VM.

![vn-conect](image.png)

**Note:** In order to run Kubectl commands on the Cluster, you will need to SSH into the VM


after you log into into the vm swith to the root user by running the follwoing command

```
sudo -i
```

ensure your cluster is running by typing the following kubectl command

```
kubectl get pods
kubectl get nodes
```

