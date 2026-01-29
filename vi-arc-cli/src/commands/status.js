/**
 * Status command - Show deployment status overview
 */

import { Command } from 'commander';
import chalk from 'chalk';
import boxen from 'boxen';
import Table from 'cli-table3';
import figures from 'figures';

import * as config from '../utils/config.js';
import { az, kubectl, withSpinner, success, error, info, warn } from '../utils/exec.js';
import {
    resourceGroupExists,
    aksClusterExists,
    arcClusterExists,
    getNodePools,
    checkAzureCli
} from '../utils/azure.js';

export const statusCommand = new Command('status')
    .description('Show deployment status overview')
    .option('--detailed', 'Show detailed status with pod information')
    .action(async (options) => {
        const cfg = config.getConfig();

        if (!cfg.resourcesPrefix) {
            console.log(boxen(
                chalk.yellow.bold('No Configuration Found') + '\n\n' +
                chalk.gray('Run the setup wizard to get started:') + '\n' +
                chalk.white('  vi-arc setup'),
                { padding: 1, borderStyle: 'round', borderColor: 'yellow' }
            ));
            return;
        }

        console.log(chalk.cyan.bold('Video Indexer Arc Deployment Status'));
        console.log();

        // Check Azure CLI status
        const azStatus = await checkAzureCli();
        if (!azStatus.loggedIn) {
            warn('Azure CLI is not logged in. Some status checks may fail.');
            console.log();
        }

        // Configuration Summary
        console.log(chalk.cyan.bold(`${figures.pointer} Configuration`));
        console.log();

        const configTable = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 50]
        });

        configTable.push(
            [chalk.gray('Resource Group'), cfg.resourceGroup],
            [chalk.gray('Region'), cfg.region],
            [chalk.gray('AKS Cluster'), cfg.aksClusterName],
            [chalk.gray('Endpoint'), cfg.viEndpointUri || chalk.yellow('Not configured')]
        );
        console.log(configTable.toString());
        console.log();

        // Resource Status
        console.log(chalk.cyan.bold(`${figures.pointer} Resource Status`));
        console.log();

        const resourceTable = new Table({
            head: [chalk.cyan('Resource'), chalk.cyan('Status'), chalk.cyan('Details')],
            style: { head: [], border: [] },
            colWidths: [25, 15, 35]
        });

        // Check resource group
        const rgStatus = await checkResourceStatus('Resource Group', async () => {
            return await resourceGroupExists(cfg.resourceGroup);
        });
        resourceTable.push(rgStatus);

        // Check AKS cluster
        const aksStatus = await checkResourceStatus('AKS Cluster', async () => {
            if (!await resourceGroupExists(cfg.resourceGroup)) return { exists: false };
            return { exists: await aksClusterExists(cfg.aksClusterName, cfg.resourceGroup) };
        });
        resourceTable.push(aksStatus);

        // Check node pools
        let poolsInfo = [];
        const poolsStatus = await checkResourceStatus('Node Pools', async () => {
            if (!await aksClusterExists(cfg.aksClusterName, cfg.resourceGroup)) {
                return { exists: false };
            }
            poolsInfo = await getNodePools(cfg.aksClusterName, cfg.resourceGroup);
            return { exists: poolsInfo.length > 0, details: `${poolsInfo.length} pool(s)` };
        });
        resourceTable.push(poolsStatus);

        // Check Arc connection
        const arcStatus = await checkResourceStatus('Arc Connection', async () => {
            if (!await resourceGroupExists(cfg.resourceGroup)) return { exists: false };
            const exists = await arcClusterExists(cfg.connectedClusterName, cfg.resourceGroup);
            if (exists) {
                try {
                    const result = await az([
                        'connectedk8s', 'show',
                        '--name', cfg.connectedClusterName,
                        '--resource-group', cfg.resourceGroup,
                        '--query', 'connectivityStatus',
                        '-o', 'tsv'
                    ], { json: false });
                    return { exists: true, details: result.trim() };
                } catch {
                    return { exists: true, details: 'Unknown' };
                }
            }
            return { exists: false };
        });
        resourceTable.push(arcStatus);

        // Check VI extension
        const extStatus = await checkResourceStatus('VI Extension', async () => {
            try {
                const result = await az([
                    'k8s-extension', 'show',
                    '--name', cfg.viExtensionName,
                    '--cluster-name', cfg.connectedClusterName,
                    '--resource-group', cfg.resourceGroup,
                    '--cluster-type', 'connectedClusters'
                ]);
                return { 
                    exists: true, 
                    details: `${result.provisioningState} (v${result.version || 'N/A'})`
                };
            } catch {
                return { exists: false };
            }
        });
        resourceTable.push(extStatus);

        console.log(resourceTable.toString());
        console.log();

        // Setup Progress
        console.log(chalk.cyan.bold(`${figures.pointer} Setup Progress`));
        console.log();

        const status = config.getSetupStatus();
        const steps = [
            { key: 'prerequisites', name: 'Prerequisites', command: 'setup' },
            { key: 'resourceGroup', name: 'Resource Group', command: 'cluster create-rg' },
            { key: 'aksCluster', name: 'AKS Cluster', command: 'cluster create' },
            { key: 'nodePools', name: 'Node Pools', command: 'cluster nodepools' },
            { key: 'gpuOperator', name: 'GPU Operator', command: 'cluster gpu-operator' },
            { key: 'ingress', name: 'Ingress Controller', command: 'cluster ingress' },
            { key: 'arcConnection', name: 'Arc Connection', command: 'cluster arc-connect' },
            { key: 'certManager', name: 'Cert Manager', command: 'cluster cert-manager' },
            { key: 'viExtension', name: 'VI Extension', command: 'extension install' }
        ];

        let completedCount = 0;
        for (const step of steps) {
            const completed = status[step.key];
            if (completed) completedCount++;
            
            const icon = completed ? chalk.green(figures.tick) : chalk.gray(figures.circle);
            const name = completed ? chalk.green(step.name) : chalk.gray(step.name);
            const command = completed ? '' : chalk.gray(` → vi-arc ${step.command}`);
            
            console.log(`  ${icon} ${name}${command}`);
        }

        const progress = Math.round((completedCount / steps.length) * 100);
        console.log();
        console.log(chalk.gray(`  Progress: ${completedCount}/${steps.length} (${progress}%)`));
        
        // Progress bar
        const barWidth = 30;
        const filled = Math.round((progress / 100) * barWidth);
        const empty = barWidth - filled;
        const progressBar = chalk.green('█'.repeat(filled)) + chalk.gray('░'.repeat(empty));
        console.log(`  [${progressBar}]`);
        console.log();

        // Detailed status
        if (options.detailed && poolsInfo.length > 0) {
            console.log(chalk.cyan.bold(`${figures.pointer} Node Pools`));
            console.log();

            const poolTable = new Table({
                head: [
                    chalk.cyan('Name'),
                    chalk.cyan('VM Size'),
                    chalk.cyan('Count'),
                    chalk.cyan('Min/Max'),
                    chalk.cyan('Status')
                ],
                style: { head: [], border: [] }
            });

            for (const pool of poolsInfo) {
                poolTable.push([
                    pool.name,
                    pool.vmSize,
                    pool.count.toString(),
                    `${pool.minCount || 0}/${pool.maxCount || pool.count}`,
                    pool.powerState?.code || 'Running'
                ]);
            }

            console.log(poolTable.toString());
            console.log();
        }

        // Show pods in video-indexer namespace if detailed
        if (options.detailed && extStatus[1] !== chalk.red('Not Found')) {
            console.log(chalk.cyan.bold(`${figures.pointer} Video Indexer Pods`));
            console.log();

            try {
                const podsOutput = await kubectl([
                    'get', 'pods',
                    '-n', 'video-indexer',
                    '--context', cfg.kubectlContext,
                    '--no-headers',
                    '-o', 'custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp'
                ]);
                
                if (podsOutput.trim()) {
                    const lines = podsOutput.trim().split('\n');
                    const podTable = new Table({
                        head: [
                            chalk.cyan('Pod'),
                            chalk.cyan('Status'),
                            chalk.cyan('Ready'),
                            chalk.cyan('Restarts')
                        ],
                        style: { head: [], border: [] }
                    });

                    for (const line of lines) {
                        const parts = line.split(/\s+/);
                        if (parts.length >= 4) {
                            const status = parts[1];
                            const statusColor = status === 'Running' ? chalk.green : 
                                              status === 'Pending' ? chalk.yellow : chalk.red;
                            podTable.push([
                                parts[0],
                                statusColor(status),
                                parts[2] === 'true' ? chalk.green('Yes') : chalk.red('No'),
                                parts[3]
                            ]);
                        }
                    }

                    console.log(podTable.toString());
                } else {
                    info('No pods found in video-indexer namespace');
                }
            } catch {
                warn('Could not fetch pods. Cluster may not be accessible.');
            }
            console.log();
        }

        // Next steps
        if (completedCount < steps.length) {
            const nextStep = steps.find(s => !status[s.key]);
            if (nextStep) {
                console.log(chalk.cyan.bold(`${figures.pointer} Next Step`));
                console.log();
                console.log(chalk.gray('  Run: ') + chalk.white(`vi-arc ${nextStep.command}`));
                console.log();
            }
        } else {
            console.log(boxen(
                chalk.green.bold('✓ Deployment Complete!') + '\n\n' +
                chalk.gray('Your Video Indexer Arc deployment is ready.') + '\n' +
                chalk.gray('Endpoint: ') + chalk.cyan(cfg.viEndpointUri),
                { padding: 1, borderStyle: 'round', borderColor: 'green' }
            ));
        }
    });

async function checkResourceStatus(name, checkFn) {
    try {
        const result = await withSpinner(`Checking ${name}...`, async () => {
            return await checkFn();
        });
        
        if (typeof result === 'object') {
            if (result.exists) {
                return [
                    chalk.gray(name),
                    chalk.green(figures.tick + ' Found'),
                    result.details || ''
                ];
            } else {
                return [
                    chalk.gray(name),
                    chalk.red('Not Found'),
                    ''
                ];
            }
        }
        
        return [
            chalk.gray(name),
            result ? chalk.green(figures.tick + ' Found') : chalk.red('Not Found'),
            ''
        ];
    } catch (err) {
        return [
            chalk.gray(name),
            chalk.yellow('Unknown'),
            err.message.substring(0, 30)
        ];
    }
}

// Quick status subcommand
statusCommand
    .command('quick')
    .description('Quick status check (no Azure API calls)')
    .action(() => {
        const cfg = config.getConfig();
        const status = config.getSetupStatus();

        if (!cfg.resourcesPrefix) {
            warn('No configuration found. Run "vi-arc setup" first.');
            return;
        }

        console.log(chalk.cyan.bold('Quick Status'));
        console.log();

        const table = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 15]
        });

        const steps = [
            ['Prerequisites', status.prerequisites],
            ['Resource Group', status.resourceGroup],
            ['AKS Cluster', status.aksCluster],
            ['Node Pools', status.nodePools],
            ['GPU Operator', status.gpuOperator],
            ['Ingress', status.ingress],
            ['Arc Connection', status.arcConnection],
            ['Cert Manager', status.certManager],
            ['VI Extension', status.viExtension]
        ];

        for (const [name, completed] of steps) {
            table.push([
                chalk.gray(name),
                completed ? chalk.green('✓ Done') : chalk.gray('○ Pending')
            ]);
        }

        console.log(table.toString());
        console.log();
        
        const completedCount = steps.filter(s => s[1]).length;
        info(`${completedCount}/${steps.length} steps completed`);
    });
