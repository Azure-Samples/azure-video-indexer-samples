/**
 * Cluster command - AKS cluster management
 */

import { Command } from 'commander';
import { prompt } from 'enquirer';
import chalk from 'chalk';
import boxen from 'boxen';
import Table from 'cli-table3';
import figures from 'figures';
import { Listr } from 'listr2';

import * as config from '../utils/config.js';
import {
    az,
    kubectl,
    helm,
    withSpinner,
    success,
    error,
    warn,
    info,
    stepHeader,
    formatDuration
} from '../utils/exec.js';
import {
    getLatestAksVersion,
    resourceGroupExists,
    aksClusterExists,
    arcClusterExists,
    getNodePools
} from '../utils/azure.js';

export const clusterCommand = new Command('cluster')
    .description('AKS cluster management commands');

// Create resource group
clusterCommand
    .command('create-rg')
    .description('Create Azure resource group')
    .action(async () => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        
        stepHeader(1, 'Create Resource Group');
        
        try {
            const exists = await resourceGroupExists(cfg.resourceGroup);
            if (exists) {
                warn(`Resource group ${cfg.resourceGroup} already exists`);
                return;
            }

            await withSpinner(`Creating resource group ${cfg.resourceGroup}...`, async () => {
                await az([
                    'group', 'create',
                    '--name', cfg.resourceGroup,
                    '--location', cfg.region,
                    '--tags', `createdBy=${cfg.resourcesPrefix}`, 'purpose=vi-arc-deployment'
                ]);
            });

            config.updateSetupStatus('resourceGroup', true);
            success(`Resource group ${cfg.resourceGroup} created successfully`);
        } catch (err) {
            error(`Failed to create resource group: ${err.message}`);
            process.exit(1);
        }
    });

// Create AKS cluster
clusterCommand
    .command('create')
    .description('Create AKS cluster')
    .option('--skip-rg', 'Skip resource group creation')
    .action(async (options) => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        
        const startTime = Date.now();
        
        try {
            // Step 1: Create resource group
            if (!options.skipRg) {
                stepHeader(1, 'Create Resource Group');
                
                const rgExists = await resourceGroupExists(cfg.resourceGroup);
                if (rgExists) {
                    info(`Resource group ${cfg.resourceGroup} already exists`);
                } else {
                    await withSpinner(`Creating resource group ${cfg.resourceGroup}...`, async () => {
                        await az([
                            'group', 'create',
                            '--name', cfg.resourceGroup,
                            '--location', cfg.region,
                            '--tags', `createdBy=${cfg.resourcesPrefix}`, 'purpose=vi-arc-deployment'
                        ]);
                    });
                    success(`Resource group created`);
                }
                config.updateSetupStatus('resourceGroup', true);
            }

            // Step 2: Install Azure CLI extensions
            stepHeader(2, 'Install Azure CLI Extensions');
            
            await withSpinner('Installing connectedk8s extension...', async () => {
                await az(['extension', 'add', '--name', 'connectedk8s', '--upgrade', '--yes'], { json: false });
            });
            await withSpinner('Installing k8s-extension extension...', async () => {
                await az(['extension', 'add', '--name', 'k8s-extension', '--upgrade', '--yes'], { json: false });
            });
            await withSpinner('Installing aks-preview extension...', async () => {
                await az(['extension', 'add', '--name', 'aks-preview', '--upgrade', '--yes'], { json: false });
            });
            
            await withSpinner('Registering required providers...', async () => {
                await az(['provider', 'register', '--namespace', 'Microsoft.Kubernetes'], { json: false });
                await az(['provider', 'register', '--namespace', 'Microsoft.KubernetesConfiguration'], { json: false });
                await az(['provider', 'register', '--namespace', 'Microsoft.ExtendedLocation'], { json: false });
            });
            
            success('Azure CLI extensions installed');

            // Step 3: Create AKS cluster
            stepHeader(3, 'Create AKS Cluster');
            
            const clusterExists = await aksClusterExists(cfg.aksClusterName, cfg.resourceGroup);
            if (clusterExists) {
                warn(`AKS cluster ${cfg.aksClusterName} already exists`);
            } else {
                console.log(chalk.gray('This may take 5-10 minutes...'));
                console.log();
                
                const aksVersion = await withSpinner('Getting latest AKS version...', async () => {
                    return await getLatestAksVersion(cfg.region);
                });
                info(`AKS Version: ${aksVersion}`);

                await withSpinner(`Creating AKS cluster ${cfg.aksClusterName}...`, async (spinner) => {
                    await az([
                        'aks', 'create',
                        '-n', cfg.aksClusterName,
                        '-g', cfg.resourceGroup,
                        '--enable-managed-identity',
                        '--enable-workload-identity',
                        '--enable-addons', 'azure-keyvault-secrets-provider',
                        '--kubernetes-version', aksVersion,
                        '--enable-oidc-issuer',
                        '--nodepool-name', 'system',
                        '--os-sku', 'AzureLinux',
                        '--node-count', '2',
                        '--tier', 'standard',
                        '--generate-ssh-keys',
                        '--network-plugin', 'kubenet',
                        '--tags', `createdBy=${cfg.resourcesPrefix}`, 'purpose=vi-arc-deployment',
                        '--node-resource-group', cfg.nodePoolResourceGroup,
                        '--node-vm-size', cfg.nodeVmSize,
                        '--enable-image-cleaner',
                        '--image-cleaner-interval-hours', '24',
                        '--node-os-upgrade-channel', 'NodeImage',
                        '--auto-upgrade-channel', 'node-image'
                    ]);
                });
                
                success('AKS cluster created');
            }

            // Step 4: Get credentials
            await withSpinner('Getting cluster credentials...', async () => {
                await az([
                    'aks', 'get-credentials',
                    '--resource-group', cfg.resourceGroup,
                    '--name', cfg.aksClusterName,
                    '--admin',
                    '--overwrite-existing',
                    '--context', cfg.kubectlContext
                ], { json: false });
            });

            // Verify connectivity
            await withSpinner('Verifying cluster connectivity...', async () => {
                await kubectl(['get', 'nodes', '--context', cfg.kubectlContext]);
            });

            config.updateSetupStatus('aksCluster', true);
            
            const duration = formatDuration(Date.now() - startTime);
            console.log();
            success(`AKS cluster setup completed in ${duration}`);
            console.log();
            info('Next: Run ' + chalk.white('vi-arc cluster nodepools') + ' to add node pools');

        } catch (err) {
            error(`Failed to create AKS cluster: ${err.message}`);
            process.exit(1);
        }
    });

// Add node pools
clusterCommand
    .command('nodepools')
    .description('Add required node pools to the AKS cluster')
    .option('--gpu-only', 'Only add GPU node pools')
    .option('--skip-gpu-summarization', 'Skip GPU summarization node pool')
    .option('--add-cpu-summarization', 'Add CPU summarization node pool')
    .action(async (options) => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        
        stepHeader(4, 'Add Node Pools');

        const startTime = Date.now();
        
        try {
            const existingPools = await getNodePools(cfg.aksClusterName, cfg.resourceGroup);
            const existingPoolNames = existingPools.map(p => p.name);

            const tasks = [];

            // Workload node pool
            if (!options.gpuOnly && !existingPoolNames.includes('workload')) {
                tasks.push({
                    title: 'Creating workload node pool',
                    task: async () => {
                        await az([
                            'aks', 'nodepool', 'add',
                            '-g', cfg.resourceGroup,
                            '--cluster-name', cfg.aksClusterName,
                            '-n', 'workload',
                            '--os-sku', 'AzureLinux',
                            '--mode', 'User',
                            '--node-vm-size', cfg.workerVmSize,
                            '--node-osdisk-size', '100',
                            '--node-count', '0',
                            '--max-count', '10',
                            '--min-count', '0',
                            '--tags', `createdBy=${cfg.resourcesPrefix}`,
                            '--enable-cluster-autoscaler',
                            '--max-pods', '110'
                        ]);
                    }
                });
            } else if (existingPoolNames.includes('workload')) {
                info('Workload node pool already exists');
            }

            // GPU Deepstream node pool
            if (!existingPoolNames.includes('gpudeepstrm')) {
                tasks.push({
                    title: 'Creating GPU deepstream node pool',
                    task: async () => {
                        await az([
                            'aks', 'nodepool', 'add',
                            '-g', cfg.resourceGroup,
                            '--cluster-name', cfg.aksClusterName,
                            '-n', 'gpudeepstrm',
                            '--os-sku', 'Ubuntu',
                            '--mode', 'User',
                            '--node-vm-size', cfg.gpuVmSize,
                            '--node-osdisk-size', '200',
                            '--node-count', '0',
                            '--max-count', '1',
                            '--min-count', '0',
                            '--tags', `createdBy=${cfg.resourcesPrefix}`,
                            '--enable-cluster-autoscaler',
                            '--node-taints', 'nvidia.com/gpu=true:NoSchedule',
                            '--labels', 'workload=deepstream',
                            '--max-pods', '110'
                        ]);
                    }
                });
            } else {
                info('GPU deepstream node pool already exists');
            }

            // GPU Summarization node pool (optional)
            if ((cfg.enableSummarizationGpu || options.addGpuSummarization) && 
                !options.skipGpuSummarization && 
                !existingPoolNames.includes('gpusumm')) {
                tasks.push({
                    title: 'Creating GPU summarization node pool',
                    task: async () => {
                        await az([
                            'aks', 'nodepool', 'add',
                            '-g', cfg.resourceGroup,
                            '--cluster-name', cfg.aksClusterName,
                            '-n', 'gpusumm',
                            '--os-sku', 'Ubuntu',
                            '--mode', 'User',
                            '--node-vm-size', cfg.gpuVmSize,
                            '--node-osdisk-size', '200',
                            '--node-count', '0',
                            '--max-count', '1',
                            '--min-count', '0',
                            '--tags', `createdBy=${cfg.resourcesPrefix}`,
                            '--enable-cluster-autoscaler',
                            '--node-taints', 'nvidia.com/gpu=true:NoSchedule',
                            '--labels', 'workload=summarization',
                            '--max-pods', '110'
                        ]);
                    }
                });
            }

            // CPU Summarization node pool (optional)
            if ((cfg.enableSummarizationCpu || options.addCpuSummarization) && 
                !existingPoolNames.includes('workloadf32')) {
                tasks.push({
                    title: 'Creating CPU summarization node pool',
                    task: async () => {
                        await az([
                            'aks', 'nodepool', 'add',
                            '-g', cfg.resourceGroup,
                            '--cluster-name', cfg.aksClusterName,
                            '-n', 'workloadf32',
                            '--os-sku', 'AzureLinux',
                            '--mode', 'User',
                            '--node-vm-size', cfg.summarizationCpuVm,
                            '--node-osdisk-size', '100',
                            '--node-count', '0',
                            '--max-count', '5',
                            '--min-count', '0',
                            '--tags', `createdBy=${cfg.resourcesPrefix}`,
                            '--enable-cluster-autoscaler',
                            '--labels', 'workload=summarization',
                            '--max-pods', '110'
                        ]);
                    }
                });
            }

            if (tasks.length === 0) {
                info('All required node pools already exist');
                return;
            }

            const listr = new Listr(tasks, { concurrent: false, exitOnError: true });
            await listr.run();

            config.updateSetupStatus('nodePools', true);
            
            const duration = formatDuration(Date.now() - startTime);
            console.log();
            success(`Node pools created in ${duration}`);
            
            // Display node pool summary
            await displayNodePoolSummary(cfg);
            
            console.log();
            info('Next: Run ' + chalk.white('vi-arc cluster gpu-operator') + ' to install NVIDIA GPU operator');

        } catch (err) {
            error(`Failed to create node pools: ${err.message}`);
            process.exit(1);
        }
    });

// Install GPU operator
clusterCommand
    .command('gpu-operator')
    .description('Install NVIDIA GPU operator')
    .action(async () => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        
        stepHeader(5, 'Install NVIDIA GPU Operator');
        console.log(chalk.gray('This may take 3-5 minutes...'));
        console.log();

        try {
            await withSpinner('Adding NVIDIA Helm repository...', async () => {
                await helm(['repo', 'add', 'nvidia', 'https://helm.ngc.nvidia.com/nvidia']);
                await helm(['repo', 'update']);
            });

            await withSpinner('Installing GPU operator...', async () => {
                await helm([
                    'upgrade', '-i', 'gpu-operator',
                    '--wait',
                    '-n', 'gpu-operator',
                    '--create-namespace',
                    '--version', 'v25.10.01',
                    'nvidia/gpu-operator',
                    '--kube-context', cfg.kubectlContext
                ]);
            });

            config.updateSetupStatus('gpuOperator', true);
            success('NVIDIA GPU operator installed');
            console.log();
            info('Next: Run ' + chalk.white('vi-arc cluster ingress') + ' to configure ingress controller');

        } catch (err) {
            error(`Failed to install GPU operator: ${err.message}`);
            process.exit(1);
        }
    });

// Configure ingress
clusterCommand
    .command('ingress')
    .description('Configure ingress controller with public IP')
    .option('--ssl <cert-uri>', 'SSL certificate URI from Key Vault')
    .action(async (options) => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        
        stepHeader(6, 'Configure Ingress Controller');

        try {
            // Create public IP
            await withSpinner('Creating static public IP...', async () => {
                await az([
                    'network', 'public-ip', 'create',
                    '-g', cfg.nodePoolResourceGroup,
                    '-n', `${cfg.resourcesPrefix}-inbound-ip`,
                    '--sku', 'Standard',
                    '--allocation-method', 'static'
                ]);
            });

            // Get public IP address
            const publicIp = await withSpinner('Getting public IP address...', async () => {
                const result = await az([
                    'network', 'public-ip', 'show',
                    '-g', cfg.nodePoolResourceGroup,
                    '-n', `${cfg.resourcesPrefix}-inbound-ip`,
                    '--query', 'ipAddress',
                    '-o', 'tsv'
                ], { json: false });
                return result.trim();
            });
            info(`Public IP: ${publicIp}`);

            // Configure DNS label
            await withSpinner('Configuring DNS label...', async () => {
                await az([
                    'network', 'public-ip', 'update',
                    '-g', cfg.nodePoolResourceGroup,
                    '-n', `${cfg.resourcesPrefix}-inbound-ip`,
                    '--dns-name', cfg.dnsLabel
                ]);
            });
            
            const fqdn = `${cfg.dnsLabel}.${cfg.region}.cloudapp.azure.com`;
            info(`FQDN: ${fqdn}`);

            // Enable app routing
            await withSpinner('Enabling app routing...', async () => {
                await az([
                    'aks', 'approuting', 'enable',
                    '-g', cfg.resourceGroup,
                    '-n', cfg.aksClusterName
                ], { json: false });
            });

            // Create nginx ingress controller
            const ingressManifest = createIngressManifest(cfg, options.ssl);
            
            await withSpinner('Creating Nginx ingress controller...', async () => {
                await kubectl([
                    'apply', '-f', '-',
                    '--context', cfg.kubectlContext
                ], { input: ingressManifest });
            });

            // Wait for ingress to get IP
            info('Waiting for ingress controller to get external IP...');
            await withSpinner('Verifying ingress controller...', async () => {
                // Wait a bit for the ingress to be created
                await new Promise(resolve => setTimeout(resolve, 10000));
                await kubectl([
                    'get', 'svc', 'nginx',
                    '-n', 'app-routing-system',
                    '--context', cfg.kubectlContext
                ]);
            });

            config.updateSetupStatus('ingress', true);
            success('Ingress controller configured');
            console.log();
            console.log(boxen(
                chalk.cyan('Endpoint Information') + '\n\n' +
                chalk.gray('Public IP: ') + chalk.white(publicIp) + '\n' +
                chalk.gray('FQDN: ') + chalk.white(fqdn) + '\n' +
                chalk.gray('Endpoint URI: ') + chalk.white(`https://${fqdn}`),
                { padding: 1, borderStyle: 'round', borderColor: 'cyan' }
            ));
            console.log();
            info('Next: Run ' + chalk.white('vi-arc cluster arc-connect') + ' to connect to Azure Arc');

        } catch (err) {
            error(`Failed to configure ingress: ${err.message}`);
            process.exit(1);
        }
    });

// Connect to Azure Arc
clusterCommand
    .command('arc-connect')
    .description('Connect AKS cluster to Azure Arc')
    .action(async () => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        
        stepHeader(7, 'Connect to Azure Arc');
        console.log(chalk.gray('This may take 3-5 minutes...'));
        console.log();

        try {
            const exists = await arcClusterExists(cfg.connectedClusterName, cfg.resourceGroup);
            if (exists) {
                warn(`Arc connected cluster ${cfg.connectedClusterName} already exists`);
            } else {
                await withSpinner(`Connecting cluster to Azure Arc...`, async () => {
                    await az([
                        'connectedk8s', 'connect',
                        '--name', cfg.connectedClusterName,
                        '--resource-group', cfg.resourceGroup,
                        '--yes'
                    ], { json: false });
                });
            }

            // Verify connection
            const status = await withSpinner('Verifying Arc connection...', async () => {
                const result = await az([
                    'connectedk8s', 'show',
                    '--name', cfg.connectedClusterName,
                    '--resource-group', cfg.resourceGroup,
                    '--query', 'connectivityStatus',
                    '-o', 'tsv'
                ], { json: false });
                return result.trim();
            });

            if (status === 'Connected') {
                config.updateSetupStatus('arcConnection', true);
                success(`Arc connection status: ${status}`);
            } else {
                warn(`Arc connection status: ${status}`);
            }
            
            console.log();
            info('Next: Run ' + chalk.white('vi-arc cluster cert-manager') + ' to install cert manager');

        } catch (err) {
            error(`Failed to connect to Azure Arc: ${err.message}`);
            process.exit(1);
        }
    });

// Install cert manager
clusterCommand
    .command('cert-manager')
    .description('Install cert manager extension')
    .action(async () => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        
        stepHeader(8, 'Install Cert Manager');

        try {
            const extName = `${cfg.aksClusterName}-certmgr`;
            
            await withSpinner('Installing cert manager extension...', async () => {
                await az([
                    'k8s-extension', 'create',
                    '--cluster-name', cfg.connectedClusterName,
                    '--name', extName,
                    '--resource-group', cfg.resourceGroup,
                    '--cluster-type', 'connectedClusters',
                    '--extension-type', 'microsoft.iotoperations.platform',
                    '--scope', 'cluster',
                    '--release-namespace', 'cert-manager'
                ]);
            });

            // Verify extension
            const status = await withSpinner('Verifying cert manager installation...', async () => {
                const result = await az([
                    'k8s-extension', 'show',
                    '--cluster-name', cfg.connectedClusterName,
                    '--resource-group', cfg.resourceGroup,
                    '--cluster-type', 'connectedClusters',
                    '--name', extName,
                    '--query', 'provisioningState',
                    '-o', 'tsv'
                ], { json: false });
                return result.trim();
            });

            if (status === 'Succeeded') {
                config.updateSetupStatus('certManager', true);
                success('Cert manager installed successfully');
            } else {
                warn(`Cert manager status: ${status}`);
            }
            
            console.log();
            info('Next: Run ' + chalk.white('vi-arc extension install') + ' to deploy Video Indexer');

        } catch (err) {
            error(`Failed to install cert manager: ${err.message}`);
            process.exit(1);
        }
    });

// Full deployment
clusterCommand
    .command('deploy')
    .description('Run full cluster deployment (all steps)')
    .option('--skip-confirmation', 'Skip confirmation prompt')
    .action(async (options) => {
        const cfg = config.getConfig();
        validateConfig(cfg);

        if (!options.skipConfirmation) {
            console.log(boxen(
                chalk.bold.cyan('Full Cluster Deployment') + '\n\n' +
                chalk.gray('This will create:') + '\n' +
                chalk.gray('  • Resource Group: ') + chalk.white(cfg.resourceGroup) + '\n' +
                chalk.gray('  • AKS Cluster: ') + chalk.white(cfg.aksClusterName) + '\n' +
                chalk.gray('  • Node Pools: ') + chalk.white('system, workload, gpudeepstrm') + '\n' +
                chalk.gray('  • GPU Operator, Ingress, Arc Connection') + '\n\n' +
                chalk.yellow('Estimated time: 20-30 minutes'),
                { padding: 1, borderStyle: 'round', borderColor: 'cyan' }
            ));

            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: 'Proceed with full deployment?',
                initial: true
            });

            if (!confirmed) {
                info('Deployment cancelled');
                return;
            }
        }

        const startTime = Date.now();

        console.log();
        console.log(chalk.cyan.bold('Starting full cluster deployment...'));
        console.log();

        const tasks = new Listr([
            {
                title: 'Create Resource Group',
                skip: () => config.isStepCompleted('resourceGroup'),
                task: async (ctx, task) => {
                    const exists = await resourceGroupExists(cfg.resourceGroup);
                    if (exists) {
                        task.skip('Resource group already exists');
                        return;
                    }
                    await az([
                        'group', 'create',
                        '--name', cfg.resourceGroup,
                        '--location', cfg.region,
                        '--tags', `createdBy=${cfg.resourcesPrefix}`, 'purpose=vi-arc-deployment'
                    ]);
                    config.updateSetupStatus('resourceGroup', true);
                }
            },
            {
                title: 'Install Azure CLI Extensions',
                task: async () => {
                    await az(['extension', 'add', '--name', 'connectedk8s', '--upgrade', '--yes'], { json: false });
                    await az(['extension', 'add', '--name', 'k8s-extension', '--upgrade', '--yes'], { json: false });
                    await az(['extension', 'add', '--name', 'aks-preview', '--upgrade', '--yes'], { json: false });
                    await az(['provider', 'register', '--namespace', 'Microsoft.Kubernetes'], { json: false });
                    await az(['provider', 'register', '--namespace', 'Microsoft.KubernetesConfiguration'], { json: false });
                    await az(['provider', 'register', '--namespace', 'Microsoft.ExtendedLocation'], { json: false });
                }
            },
            {
                title: 'Create AKS Cluster',
                skip: () => config.isStepCompleted('aksCluster'),
                task: async (ctx, task) => {
                    const exists = await aksClusterExists(cfg.aksClusterName, cfg.resourceGroup);
                    if (exists) {
                        task.skip('AKS cluster already exists');
                        config.updateSetupStatus('aksCluster', true);
                        return;
                    }
                    
                    task.output = 'Getting latest AKS version...';
                    const aksVersion = await getLatestAksVersion(cfg.region);
                    
                    task.output = 'Creating cluster (this takes 5-10 minutes)...';
                    await az([
                        'aks', 'create',
                        '-n', cfg.aksClusterName,
                        '-g', cfg.resourceGroup,
                        '--enable-managed-identity',
                        '--enable-workload-identity',
                        '--enable-addons', 'azure-keyvault-secrets-provider',
                        '--kubernetes-version', aksVersion,
                        '--enable-oidc-issuer',
                        '--nodepool-name', 'system',
                        '--os-sku', 'AzureLinux',
                        '--node-count', '2',
                        '--tier', 'standard',
                        '--generate-ssh-keys',
                        '--network-plugin', 'kubenet',
                        '--tags', `createdBy=${cfg.resourcesPrefix}`, 'purpose=vi-arc-deployment',
                        '--node-resource-group', cfg.nodePoolResourceGroup,
                        '--node-vm-size', cfg.nodeVmSize,
                        '--enable-image-cleaner',
                        '--image-cleaner-interval-hours', '24',
                        '--node-os-upgrade-channel', 'NodeImage',
                        '--auto-upgrade-channel', 'node-image'
                    ]);
                    config.updateSetupStatus('aksCluster', true);
                },
                options: { bottomBar: Infinity }
            },
            {
                title: 'Get Cluster Credentials',
                task: async () => {
                    await az([
                        'aks', 'get-credentials',
                        '--resource-group', cfg.resourceGroup,
                        '--name', cfg.aksClusterName,
                        '--admin',
                        '--overwrite-existing',
                        '--context', cfg.kubectlContext
                    ], { json: false });
                }
            },
            {
                title: 'Create Node Pools',
                skip: () => config.isStepCompleted('nodePools'),
                task: async (ctx, task) => {
                    const existingPools = await getNodePools(cfg.aksClusterName, cfg.resourceGroup);
                    const existingPoolNames = existingPools.map(p => p.name);
                    
                    if (!existingPoolNames.includes('workload')) {
                        task.output = 'Creating workload node pool...';
                        await az([
                            'aks', 'nodepool', 'add',
                            '-g', cfg.resourceGroup,
                            '--cluster-name', cfg.aksClusterName,
                            '-n', 'workload',
                            '--os-sku', 'AzureLinux',
                            '--mode', 'User',
                            '--node-vm-size', cfg.workerVmSize,
                            '--node-osdisk-size', '100',
                            '--node-count', '0',
                            '--max-count', '10',
                            '--min-count', '0',
                            '--enable-cluster-autoscaler',
                            '--max-pods', '110'
                        ]);
                    }
                    
                    if (!existingPoolNames.includes('gpudeepstrm')) {
                        task.output = 'Creating GPU deepstream node pool...';
                        await az([
                            'aks', 'nodepool', 'add',
                            '-g', cfg.resourceGroup,
                            '--cluster-name', cfg.aksClusterName,
                            '-n', 'gpudeepstrm',
                            '--os-sku', 'Ubuntu',
                            '--mode', 'User',
                            '--node-vm-size', cfg.gpuVmSize,
                            '--node-osdisk-size', '200',
                            '--node-count', '0',
                            '--max-count', '1',
                            '--min-count', '0',
                            '--enable-cluster-autoscaler',
                            '--node-taints', 'nvidia.com/gpu=true:NoSchedule',
                            '--labels', 'workload=deepstream',
                            '--max-pods', '110'
                        ]);
                    }
                    
                    config.updateSetupStatus('nodePools', true);
                },
                options: { bottomBar: Infinity }
            },
            {
                title: 'Install NVIDIA GPU Operator',
                skip: () => config.isStepCompleted('gpuOperator'),
                task: async () => {
                    await helm(['repo', 'add', 'nvidia', 'https://helm.ngc.nvidia.com/nvidia']);
                    await helm(['repo', 'update']);
                    await helm([
                        'upgrade', '-i', 'gpu-operator',
                        '--wait',
                        '-n', 'gpu-operator',
                        '--create-namespace',
                        '--version', 'v25.10.01',
                        'nvidia/gpu-operator',
                        '--kube-context', cfg.kubectlContext
                    ]);
                    config.updateSetupStatus('gpuOperator', true);
                }
            },
            {
                title: 'Configure Ingress Controller',
                skip: () => config.isStepCompleted('ingress'),
                task: async (ctx, task) => {
                    task.output = 'Creating public IP...';
                    await az([
                        'network', 'public-ip', 'create',
                        '-g', cfg.nodePoolResourceGroup,
                        '-n', `${cfg.resourcesPrefix}-inbound-ip`,
                        '--sku', 'Standard',
                        '--allocation-method', 'static'
                    ]);
                    
                    task.output = 'Configuring DNS...';
                    await az([
                        'network', 'public-ip', 'update',
                        '-g', cfg.nodePoolResourceGroup,
                        '-n', `${cfg.resourcesPrefix}-inbound-ip`,
                        '--dns-name', cfg.dnsLabel
                    ]);
                    
                    task.output = 'Enabling app routing...';
                    await az([
                        'aks', 'approuting', 'enable',
                        '-g', cfg.resourceGroup,
                        '-n', cfg.aksClusterName
                    ], { json: false });
                    
                    task.output = 'Creating nginx ingress controller...';
                    const manifest = createIngressManifest(cfg);
                    await kubectl([
                        'apply', '-f', '-',
                        '--context', cfg.kubectlContext
                    ], { input: manifest });
                    
                    config.updateSetupStatus('ingress', true);
                },
                options: { bottomBar: Infinity }
            },
            {
                title: 'Connect to Azure Arc',
                skip: () => config.isStepCompleted('arcConnection'),
                task: async () => {
                    const exists = await arcClusterExists(cfg.connectedClusterName, cfg.resourceGroup);
                    if (!exists) {
                        await az([
                            'connectedk8s', 'connect',
                            '--name', cfg.connectedClusterName,
                            '--resource-group', cfg.resourceGroup,
                            '--yes'
                        ], { json: false });
                    }
                    config.updateSetupStatus('arcConnection', true);
                }
            },
            {
                title: 'Install Cert Manager',
                skip: () => config.isStepCompleted('certManager'),
                task: async () => {
                    const extName = `${cfg.aksClusterName}-certmgr`;
                    await az([
                        'k8s-extension', 'create',
                        '--cluster-name', cfg.connectedClusterName,
                        '--name', extName,
                        '--resource-group', cfg.resourceGroup,
                        '--cluster-type', 'connectedClusters',
                        '--extension-type', 'microsoft.iotoperations.platform',
                        '--scope', 'cluster',
                        '--release-namespace', 'cert-manager'
                    ]);
                    config.updateSetupStatus('certManager', true);
                }
            }
        ], {
            concurrent: false,
            exitOnError: true,
            rendererOptions: {
                showTimer: true,
                collapseSubtasks: false
            }
        });

        try {
            await tasks.run();
            
            const duration = formatDuration(Date.now() - startTime);
            console.log();
            console.log(boxen(
                chalk.green.bold('✓ Cluster Deployment Complete!') + '\n\n' +
                chalk.gray('Duration: ') + chalk.white(duration) + '\n\n' +
                chalk.gray('Next step: Deploy Video Indexer extension') + '\n' +
                chalk.white('vi-arc extension install'),
                { padding: 1, borderStyle: 'round', borderColor: 'green' }
            ));
        } catch (err) {
            console.log();
            error(`Deployment failed: ${err.message}`);
            info('You can resume from where it left off by running the command again');
            process.exit(1);
        }
    });

function validateConfig(cfg) {
    if (!cfg.subscriptionId || !cfg.region || !cfg.resourcesPrefix) {
        error('Configuration not initialized. Run "vi-arc setup" first.');
        process.exit(1);
    }
}

function createIngressManifest(cfg, sslCertUri = null) {
    const manifest = {
        apiVersion: 'approuting.kubernetes.azure.com/v1alpha1',
        kind: 'NginxIngressController',
        metadata: {
            name: 'nginx'
        },
        spec: {
            ingressClassName: 'nginx',
            controllerNamePrefix: 'nginx',
            loadBalancerAnnotations: {
                'service.beta.kubernetes.io/azure-pip-name': `${cfg.resourcesPrefix}-inbound-ip`,
                'service.beta.kubernetes.io/azure-load-balancer-resource-group': cfg.nodePoolResourceGroup
            }
        }
    };

    if (sslCertUri) {
        manifest.spec.defaultSSLCertificate = {
            keyVaultURI: sslCertUri
        };
    }

    return JSON.stringify(manifest);
}

async function displayNodePoolSummary(cfg) {
    const pools = await getNodePools(cfg.aksClusterName, cfg.resourceGroup);
    
    console.log();
    console.log(chalk.cyan.bold('Node Pool Summary:'));
    console.log();
    
    const table = new Table({
        head: [
            chalk.cyan('Name'),
            chalk.cyan('VM Size'),
            chalk.cyan('Count'),
            chalk.cyan('Min/Max'),
            chalk.cyan('Mode')
        ],
        style: { head: [], border: [] }
    });

    for (const pool of pools) {
        table.push([
            pool.name,
            pool.vmSize,
            pool.count.toString(),
            `${pool.minCount || 0}/${pool.maxCount || pool.count}`,
            pool.mode
        ]);
    }

    console.log(table.toString());
}
