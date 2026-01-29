/**
 * K8s command - Generic Kubernetes cluster setup (for non-AKS clusters)
 * Steps 5-9: GPU Operator, Ingress, Arc, Cert Manager, VI Extension
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
import { arcClusterExists } from '../utils/azure.js';

export const k8sCommand = new Command('k8s')
    .description('Generic Kubernetes cluster setup (for non-AKS clusters like Azure Local, on-prem, etc.)');

// Initialize for existing cluster
k8sCommand
    .command('init')
    .description('Initialize configuration for an existing Kubernetes cluster')
    .option('--context <context>', 'kubectl context name')
    .option('--region <region>', 'Azure region for Arc connection')
    .option('--prefix <prefix>', 'Resource naming prefix')
    .action(async (options) => {
        console.log(boxen(
            chalk.bold.cyan('Initialize Existing Kubernetes Cluster') + '\n\n' +
            chalk.gray('This will configure VI Arc CLI to work with your existing cluster.\n') +
            chalk.gray('Make sure kubectl is configured and can access your cluster.'),
            { padding: 1, borderStyle: 'round', borderColor: 'cyan' }
        ));
        console.log();

        try {
            // Check kubectl connectivity
            let context = options.context;
            
            if (!context) {
                const contexts = await getKubeContexts();
                if (contexts.length === 0) {
                    error('No kubectl contexts found. Configure kubectl first.');
                    process.exit(1);
                }

                const { selectedContext } = await prompt({
                    type: 'select',
                    name: 'selectedContext',
                    message: 'Select kubectl context:',
                    choices: contexts.map(c => ({
                        name: `${c.name}${c.current ? ' (current)' : ''}`,
                        value: c.name
                    }))
                });
                context = selectedContext;
            }

            // Verify connectivity
            await withSpinner(`Verifying cluster connectivity...`, async () => {
                await kubectl(['cluster-info', '--context', context]);
            });
            success('Cluster is accessible');

            // Get region
            let region = options.region;
            if (!region) {
                const gpuRegions = [
                    'eastus', 'eastus2', 'westus2', 'westus3',
                    'centralus', 'northcentralus', 'southcentralus',
                    'westeurope', 'northeurope', 'uksouth',
                    'southeastasia', 'eastasia', 'australiaeast', 'japaneast'
                ];
                
                const { selectedRegion } = await prompt({
                    type: 'autocomplete',
                    name: 'selectedRegion',
                    message: 'Select Azure region for Arc connection:',
                    choices: gpuRegions
                });
                region = selectedRegion;
            }

            // Get prefix
            let prefix = options.prefix;
            if (!prefix) {
                const { inputPrefix } = await prompt({
                    type: 'input',
                    name: 'inputPrefix',
                    message: 'Enter resource naming prefix:',
                    initial: 'vi-arc',
                    validate: v => v?.length >= 3 || 'Prefix must be at least 3 characters'
                });
                prefix = inputPrefix;
            }

            // Get subscription
            const subscription = await withSpinner('Getting Azure subscription...', async () => {
                return await az(['account', 'show']);
            });

            // Initialize config
            const randomSuffix = Math.floor(Math.random() * 900 + 100).toString();
            
            config.setMultiple({
                subscriptionId: subscription.id,
                region,
                resourcesPrefix: prefix,
                randomSuffix,
                resourceGroup: `${prefix}-rg`,
                connectedClusterName: `${prefix}-connected-k8s`,
                kubectlContext: context,
                dnsLabel: `${prefix}${randomSuffix}`,
                viEndpointUri: `https://${prefix}${randomSuffix}.${region}.cloudapp.azure.com`,
                isExistingCluster: true // Flag to indicate this is not AKS
            });

            // Mark AKS steps as N/A for existing clusters
            config.updateSetupStatus('prerequisites', true);
            config.updateSetupStatus('resourceGroup', false);
            config.updateSetupStatus('aksCluster', true); // Not applicable
            config.updateSetupStatus('nodePools', true);  // Not applicable

            success('Configuration initialized for existing cluster');
            console.log();
            
            console.log(chalk.cyan('Configuration:'));
            console.log(chalk.gray(`  Context: ${context}`));
            console.log(chalk.gray(`  Region: ${region}`));
            console.log(chalk.gray(`  Connected Cluster Name: ${prefix}-connected-k8s`));
            console.log();
            
            console.log(chalk.cyan('Next steps:'));
            console.log(chalk.gray('  1. Run ') + chalk.white('vi-arc k8s gpu-operator') + chalk.gray(' to install NVIDIA GPU operator'));
            console.log(chalk.gray('  2. Run ') + chalk.white('vi-arc k8s arc-connect') + chalk.gray(' to connect to Azure Arc'));
            console.log(chalk.gray('  3. Run ') + chalk.white('vi-arc k8s cert-manager') + chalk.gray(' to install cert manager'));
            console.log(chalk.gray('  4. Run ') + chalk.white('vi-arc extension install') + chalk.gray(' to deploy Video Indexer'));
            console.log();
            console.log(chalk.gray('Or run ') + chalk.white('vi-arc k8s deploy') + chalk.gray(' for automated deployment'));

        } catch (err) {
            error(`Initialization failed: ${err.message}`);
            process.exit(1);
        }
    });

// Install GPU operator (generic)
k8sCommand
    .command('gpu-operator')
    .description('Install NVIDIA GPU operator on any Kubernetes cluster')
    .option('--version <version>', 'GPU operator version', 'v25.10.01')
    .option('--skip-drivers', 'Skip driver installation (use if drivers are pre-installed)')
    .action(async (options) => {
        const cfg = config.getConfig();
        
        stepHeader(5, 'Install NVIDIA GPU Operator');
        console.log(chalk.gray('This may take 3-5 minutes...'));
        console.log();

        try {
            await withSpinner('Adding NVIDIA Helm repository...', async () => {
                await helm(['repo', 'add', 'nvidia', 'https://helm.ngc.nvidia.com/nvidia']);
                await helm(['repo', 'update']);
            });

            const helmArgs = [
                'upgrade', '-i', 'gpu-operator',
                '--wait',
                '-n', 'gpu-operator',
                '--create-namespace',
                '--version', options.version,
                'nvidia/gpu-operator'
            ];

            if (cfg.kubectlContext) {
                helmArgs.push('--kube-context', cfg.kubectlContext);
            }

            if (options.skipDrivers) {
                helmArgs.push('--set', 'driver.enabled=false');
            }

            await withSpinner('Installing GPU operator...', async () => {
                await helm(helmArgs);
            });

            config.updateSetupStatus('gpuOperator', true);
            success('NVIDIA GPU operator installed');
            console.log();
            info('Next: Run ' + chalk.white('vi-arc k8s arc-connect') + ' to connect to Azure Arc');

        } catch (err) {
            error(`Failed to install GPU operator: ${err.message}`);
            process.exit(1);
        }
    });

// Connect to Azure Arc (generic)
k8sCommand
    .command('arc-connect')
    .description('Connect Kubernetes cluster to Azure Arc')
    .option('--rg <resourceGroup>', 'Resource group for Arc connection')
    .action(async (options) => {
        const cfg = config.getConfig();
        
        stepHeader(7, 'Connect to Azure Arc');
        console.log(chalk.gray('This may take 3-5 minutes...'));
        console.log();

        try {
            const resourceGroup = options.rg || cfg.resourceGroup;
            const connectedClusterName = cfg.connectedClusterName || `${cfg.resourcesPrefix}-connected-k8s`;

            // Create resource group if needed
            await withSpinner(`Ensuring resource group ${resourceGroup} exists...`, async () => {
                try {
                    await az(['group', 'show', '--name', resourceGroup]);
                } catch {
                    await az([
                        'group', 'create',
                        '--name', resourceGroup,
                        '--location', cfg.region
                    ]);
                }
            });
            config.updateSetupStatus('resourceGroup', true);

            // Install Azure CLI extensions
            await withSpinner('Installing Azure CLI extensions...', async () => {
                await az(['extension', 'add', '--name', 'connectedk8s', '--upgrade', '--yes'], { json: false });
                await az(['extension', 'add', '--name', 'k8s-extension', '--upgrade', '--yes'], { json: false });
            });

            // Check if already connected
            const exists = await arcClusterExists(connectedClusterName, resourceGroup);
            if (exists) {
                warn(`Arc connected cluster ${connectedClusterName} already exists`);
            } else {
                const connectArgs = [
                    'connectedk8s', 'connect',
                    '--name', connectedClusterName,
                    '--resource-group', resourceGroup,
                    '--yes'
                ];

                if (cfg.kubectlContext) {
                    connectArgs.push('--kube-context', cfg.kubectlContext);
                }

                await withSpinner('Connecting cluster to Azure Arc...', async () => {
                    await az(connectArgs, { json: false });
                });
            }

            // Verify connection
            const status = await withSpinner('Verifying Arc connection...', async () => {
                const result = await az([
                    'connectedk8s', 'show',
                    '--name', connectedClusterName,
                    '--resource-group', resourceGroup,
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

            // Save connected cluster name
            config.set('connectedClusterName', connectedClusterName);
            config.set('resourceGroup', resourceGroup);

            console.log();
            info('Next: Run ' + chalk.white('vi-arc k8s cert-manager') + ' to install cert manager');

        } catch (err) {
            error(`Failed to connect to Azure Arc: ${err.message}`);
            process.exit(1);
        }
    });

// Install cert manager (generic)
k8sCommand
    .command('cert-manager')
    .description('Install cert manager extension on Arc-connected cluster')
    .action(async () => {
        const cfg = config.getConfig();
        
        stepHeader(8, 'Install Cert Manager');

        try {
            const extName = `${cfg.resourcesPrefix}-certmgr`;
            
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

// Configure ingress (generic)
k8sCommand
    .command('ingress')
    .description('Configure ingress for external access')
    .option('--external-ip <ip>', 'External IP address (if pre-assigned)')
    .option('--hostname <hostname>', 'Hostname for ingress')
    .option('--class <class>', 'Ingress class name', 'nginx')
    .action(async (options) => {
        const cfg = config.getConfig();
        
        stepHeader(6, 'Configure Ingress');

        try {
            // If external IP provided, use it
            if (options.externalIp) {
                config.set('externalIp', options.externalIp);
                info(`Using external IP: ${options.externalIp}`);
            }

            if (options.hostname) {
                config.set('viEndpointUri', `https://${options.hostname}`);
                info(`Endpoint URI: https://${options.hostname}`);
            }

            // Check if nginx ingress controller exists
            await withSpinner('Checking ingress controller...', async () => {
                const context = cfg.kubectlContext;
                const args = ['get', 'ingressclass'];
                if (context) args.push('--context', context);
                
                await kubectl(args);
            });

            success('Ingress configuration saved');
            console.log();
            
            console.log(boxen(
                chalk.cyan('Ingress Configuration') + '\n\n' +
                chalk.gray('For external access, ensure:') + '\n' +
                chalk.gray('  1. Ingress controller is installed (nginx, traefik, etc.)') + '\n' +
                chalk.gray('  2. External IP or LoadBalancer is configured') + '\n' +
                chalk.gray('  3. DNS points to your cluster\'s external IP') + '\n\n' +
                chalk.gray('Endpoint URI: ') + chalk.white(cfg.viEndpointUri || 'Not configured'),
                { padding: 1, borderStyle: 'round', borderColor: 'cyan' }
            ));

            config.updateSetupStatus('ingress', true);

        } catch (err) {
            error(`Failed to configure ingress: ${err.message}`);
            process.exit(1);
        }
    });

// Full deployment for existing cluster
k8sCommand
    .command('deploy')
    .description('Run full deployment on existing Kubernetes cluster')
    .option('--skip-gpu', 'Skip GPU operator installation')
    .option('--skip-confirmation', 'Skip confirmation prompt')
    .action(async (options) => {
        const cfg = config.getConfig();
        
        if (!cfg.kubectlContext && !cfg.isExistingCluster) {
            error('No cluster configured. Run "vi-arc k8s init" first.');
            process.exit(1);
        }

        if (!options.skipConfirmation) {
            console.log(boxen(
                chalk.bold.cyan('Deploy Video Indexer on Existing Cluster') + '\n\n' +
                chalk.gray('This will:') + '\n' +
                chalk.gray('  • Install NVIDIA GPU Operator (if not skipped)') + '\n' +
                chalk.gray('  • Connect cluster to Azure Arc') + '\n' +
                chalk.gray('  • Install Cert Manager') + '\n' +
                chalk.gray('  • Deploy Video Indexer Extension') + '\n\n' +
                chalk.gray('Cluster Context: ') + chalk.white(cfg.kubectlContext || 'default') + '\n' +
                chalk.gray('Resource Group: ') + chalk.white(cfg.resourceGroup) + '\n' +
                chalk.yellow('\nEstimated time: 15-25 minutes'),
                { padding: 1, borderStyle: 'round', borderColor: 'cyan' }
            ));

            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: 'Proceed with deployment?',
                initial: true
            });

            if (!confirmed) {
                info('Deployment cancelled');
                return;
            }
        }

        const startTime = Date.now();

        const tasks = new Listr([
            {
                title: 'Install Azure CLI Extensions',
                task: async () => {
                    await az(['extension', 'add', '--name', 'connectedk8s', '--upgrade', '--yes'], { json: false });
                    await az(['extension', 'add', '--name', 'k8s-extension', '--upgrade', '--yes'], { json: false });
                    await az(['provider', 'register', '--namespace', 'Microsoft.Kubernetes'], { json: false });
                    await az(['provider', 'register', '--namespace', 'Microsoft.KubernetesConfiguration'], { json: false });
                }
            },
            {
                title: 'Create Resource Group',
                skip: () => config.isStepCompleted('resourceGroup'),
                task: async () => {
                    try {
                        await az(['group', 'show', '--name', cfg.resourceGroup]);
                    } catch {
                        await az([
                            'group', 'create',
                            '--name', cfg.resourceGroup,
                            '--location', cfg.region
                        ]);
                    }
                    config.updateSetupStatus('resourceGroup', true);
                }
            },
            {
                title: 'Install NVIDIA GPU Operator',
                skip: () => options.skipGpu || config.isStepCompleted('gpuOperator'),
                task: async () => {
                    await helm(['repo', 'add', 'nvidia', 'https://helm.ngc.nvidia.com/nvidia']);
                    await helm(['repo', 'update']);
                    
                    const helmArgs = [
                        'upgrade', '-i', 'gpu-operator',
                        '--wait',
                        '-n', 'gpu-operator',
                        '--create-namespace',
                        '--version', 'v25.10.01',
                        'nvidia/gpu-operator'
                    ];
                    if (cfg.kubectlContext) {
                        helmArgs.push('--kube-context', cfg.kubectlContext);
                    }
                    
                    await helm(helmArgs);
                    config.updateSetupStatus('gpuOperator', true);
                }
            },
            {
                title: 'Connect to Azure Arc',
                skip: () => config.isStepCompleted('arcConnection'),
                task: async () => {
                    const exists = await arcClusterExists(cfg.connectedClusterName, cfg.resourceGroup);
                    if (!exists) {
                        const args = [
                            'connectedk8s', 'connect',
                            '--name', cfg.connectedClusterName,
                            '--resource-group', cfg.resourceGroup,
                            '--yes'
                        ];
                        if (cfg.kubectlContext) {
                            args.push('--kube-context', cfg.kubectlContext);
                        }
                        await az(args, { json: false });
                    }
                    config.updateSetupStatus('arcConnection', true);
                }
            },
            {
                title: 'Install Cert Manager',
                skip: () => config.isStepCompleted('certManager'),
                task: async () => {
                    const extName = `${cfg.resourcesPrefix}-certmgr`;
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
            rendererOptions: { showTimer: true }
        });

        try {
            await tasks.run();
            
            const duration = formatDuration(Date.now() - startTime);
            console.log();
            console.log(boxen(
                chalk.green.bold('✓ Cluster Setup Complete!') + '\n\n' +
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

// Helper function to get kubectl contexts
async function getKubeContexts() {
    try {
        const output = await kubectl([
            'config', 'get-contexts',
            '-o', 'name'
        ]);
        
        const currentContext = await kubectl([
            'config', 'current-context'
        ]).catch(() => '');
        
        return output.trim().split('\n').filter(Boolean).map(name => ({
            name: name.trim(),
            current: name.trim() === currentContext.trim()
        }));
    } catch {
        return [];
    }
}

// Verify cluster requirements
k8sCommand
    .command('verify')
    .description('Verify cluster meets Video Indexer Arc requirements')
    .action(async () => {
        const cfg = config.getConfig();
        
        console.log(chalk.cyan.bold('Verifying Cluster Requirements'));
        console.log();

        const checks = [];
        
        // Check kubectl connectivity
        checks.push({
            name: 'Cluster Connectivity',
            check: async () => {
                await kubectl(['cluster-info', '--context', cfg.kubectlContext || '']);
                return true;
            }
        });

        // Check node count
        checks.push({
            name: 'Node Count (min 2)',
            check: async () => {
                const output = await kubectl([
                    'get', 'nodes', '-o', 'json',
                    '--context', cfg.kubectlContext || ''
                ]);
                const nodes = JSON.parse(output);
                return nodes.items.length >= 2;
            }
        });

        // Check GPU nodes
        checks.push({
            name: 'GPU Nodes Available',
            check: async () => {
                try {
                    const output = await kubectl([
                        'get', 'nodes', '-l', 'nvidia.com/gpu',
                        '-o', 'json',
                        '--context', cfg.kubectlContext || ''
                    ]);
                    const nodes = JSON.parse(output);
                    return nodes.items.length > 0;
                } catch {
                    return false;
                }
            }
        });

        // Check GPU operator
        checks.push({
            name: 'GPU Operator Installed',
            check: async () => {
                try {
                    await kubectl([
                        'get', 'pods', '-n', 'gpu-operator',
                        '--context', cfg.kubectlContext || ''
                    ]);
                    return true;
                } catch {
                    return false;
                }
            }
        });

        // Check Arc connection
        checks.push({
            name: 'Azure Arc Connected',
            check: async () => {
                try {
                    await kubectl([
                        'get', 'pods', '-n', 'azure-arc',
                        '--context', cfg.kubectlContext || ''
                    ]);
                    return true;
                } catch {
                    return false;
                }
            }
        });

        const table = new Table({
            head: [chalk.cyan('Check'), chalk.cyan('Status')],
            style: { head: [], border: [] }
        });

        for (const check of checks) {
            try {
                const result = await withSpinner(`Checking ${check.name}...`, async () => {
                    return await check.check();
                });
                
                table.push([
                    check.name,
                    result ? chalk.green(`${figures.tick} Passed`) : chalk.yellow(`${figures.warning} Warning`)
                ]);
            } catch (err) {
                table.push([
                    check.name,
                    chalk.red(`${figures.cross} Failed`)
                ]);
            }
        }

        console.log(table.toString());
    });
