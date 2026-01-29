/**
 * Cleanup command - Delete all created resources
 */

import { Command } from 'commander';
import { prompt } from 'enquirer';
import chalk from 'chalk';
import boxen from 'boxen';
import figures from 'figures';
import { Listr } from 'listr2';

import * as config from '../utils/config.js';
import { az, withSpinner, success, error, warn, info } from '../utils/exec.js';
import { resourceGroupExists, arcClusterExists } from '../utils/azure.js';

export const cleanupCommand = new Command('cleanup')
    .description('Delete all created resources')
    .option('--yes', 'Skip confirmation prompts')
    .option('--keep-rg', 'Keep the resource group (only delete individual resources)')
    .option('--extension-only', 'Only delete the Video Indexer extension')
    .action(async (options) => {
        const cfg = config.getConfig();

        if (!cfg.resourceGroup) {
            error('No configuration found. Nothing to clean up.');
            return;
        }

        console.log(boxen(
            chalk.red.bold('⚠️  Resource Cleanup') + '\n\n' +
            chalk.gray('This will delete the following resources:') + '\n\n' +
            (options.extensionOnly 
                ? chalk.white(`  • Video Indexer Extension: ${cfg.viExtensionName}`)
                : chalk.white(`  • Resource Group: ${cfg.resourceGroup}\n`) +
                  chalk.white(`  • AKS Cluster: ${cfg.aksClusterName}\n`) +
                  chalk.white(`  • Arc Connected Cluster: ${cfg.connectedClusterName}\n`) +
                  chalk.white(`  • All node pools and associated resources`)) + '\n\n' +
            chalk.yellow('This action cannot be undone!'),
            { padding: 1, borderStyle: 'round', borderColor: 'red' }
        ));
        console.log();

        if (!options.yes) {
            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: chalk.red('Are you sure you want to delete these resources?'),
                initial: false
            });

            if (!confirmed) {
                info('Cleanup cancelled');
                return;
            }

            // Double confirmation for destructive action
            const { doubleConfirm } = await prompt({
                type: 'input',
                name: 'doubleConfirm',
                message: `Type "${cfg.resourceGroup}" to confirm deletion:`,
                validate: (value) => {
                    if (options.extensionOnly) return true;
                    return value === cfg.resourceGroup || 'Resource group name does not match';
                }
            });

            if (!options.extensionOnly && doubleConfirm !== cfg.resourceGroup) {
                info('Cleanup cancelled');
                return;
            }
        }

        console.log();

        if (options.extensionOnly) {
            await cleanupExtensionOnly(cfg);
        } else if (options.keepRg) {
            await cleanupKeepResourceGroup(cfg);
        } else {
            await cleanupAll(cfg);
        }
    });

async function cleanupExtensionOnly(cfg) {
    try {
        await withSpinner('Deleting Video Indexer extension...', async () => {
            await az([
                'k8s-extension', 'delete',
                '--name', cfg.viExtensionName,
                '--cluster-name', cfg.connectedClusterName,
                '--resource-group', cfg.resourceGroup,
                '--cluster-type', 'connectedClusters',
                '--yes'
            ], { json: false });
        });

        config.updateSetupStatus('viExtension', false);
        success('Video Indexer extension deleted');
    } catch (err) {
        warn(`Could not delete extension: ${err.message}`);
    }
}

async function cleanupKeepResourceGroup(cfg) {
    const tasks = new Listr([
        {
            title: 'Delete Video Indexer Extension',
            task: async (ctx, task) => {
                try {
                    await az([
                        'k8s-extension', 'delete',
                        '--name', cfg.viExtensionName,
                        '--cluster-name', cfg.connectedClusterName,
                        '--resource-group', cfg.resourceGroup,
                        '--cluster-type', 'connectedClusters',
                        '--yes'
                    ], { json: false });
                    config.updateSetupStatus('viExtension', false);
                } catch {
                    task.skip('Extension not found');
                }
            }
        },
        {
            title: 'Delete Cert Manager Extension',
            task: async (ctx, task) => {
                try {
                    const extName = `${cfg.aksClusterName}-certmgr`;
                    await az([
                        'k8s-extension', 'delete',
                        '--name', extName,
                        '--cluster-name', cfg.connectedClusterName,
                        '--resource-group', cfg.resourceGroup,
                        '--cluster-type', 'connectedClusters',
                        '--yes'
                    ], { json: false });
                    config.updateSetupStatus('certManager', false);
                } catch {
                    task.skip('Cert manager not found');
                }
            }
        },
        {
            title: 'Disconnect from Azure Arc',
            task: async (ctx, task) => {
                const exists = await arcClusterExists(cfg.connectedClusterName, cfg.resourceGroup);
                if (!exists) {
                    task.skip('Arc connection not found');
                    return;
                }
                
                await az([
                    'connectedk8s', 'delete',
                    '--name', cfg.connectedClusterName,
                    '--resource-group', cfg.resourceGroup,
                    '--yes'
                ], { json: false });
                config.updateSetupStatus('arcConnection', false);
            }
        },
        {
            title: 'Delete AKS Cluster',
            task: async (ctx, task) => {
                try {
                    await az([
                        'aks', 'delete',
                        '--name', cfg.aksClusterName,
                        '--resource-group', cfg.resourceGroup,
                        '--yes',
                        '--no-wait'
                    ], { json: false });
                    config.updateSetupStatus('aksCluster', false);
                    config.updateSetupStatus('nodePools', false);
                    config.updateSetupStatus('gpuOperator', false);
                    config.updateSetupStatus('ingress', false);
                } catch {
                    task.skip('AKS cluster not found');
                }
            }
        }
    ], {
        concurrent: false,
        exitOnError: false
    });

    try {
        await tasks.run();
        console.log();
        success('Resources deleted (resource group kept)');
        info('To delete the resource group, run: ' + chalk.white(`az group delete --name ${cfg.resourceGroup}`));
    } catch (err) {
        error(`Cleanup failed: ${err.message}`);
    }
}

async function cleanupAll(cfg) {
    const tasks = new Listr([
        {
            title: 'Delete Arc Connection',
            task: async (ctx, task) => {
                const exists = await arcClusterExists(cfg.connectedClusterName, cfg.resourceGroup);
                if (!exists) {
                    task.skip('Arc connection not found');
                    return;
                }
                
                try {
                    await az([
                        'connectedk8s', 'delete',
                        '--name', cfg.connectedClusterName,
                        '--resource-group', cfg.resourceGroup,
                        '--yes'
                    ], { json: false });
                } catch {
                    task.skip('Could not delete Arc connection');
                }
            }
        },
        {
            title: 'Delete Resource Group',
            task: async (ctx, task) => {
                const exists = await resourceGroupExists(cfg.resourceGroup);
                if (!exists) {
                    task.skip('Resource group not found');
                    return;
                }
                
                task.output = 'Deleting resource group (this will delete all contained resources)...';
                await az([
                    'group', 'delete',
                    '--name', cfg.resourceGroup,
                    '--yes',
                    '--no-wait'
                ], { json: false });
            },
            options: { bottomBar: Infinity }
        }
    ], {
        concurrent: false,
        exitOnError: false
    });

    try {
        await tasks.run();
        
        // Clear configuration
        const { clearConfig: shouldClear } = await prompt({
            type: 'confirm',
            name: 'clearConfig',
            message: 'Clear local configuration?',
            initial: true
        });

        if (shouldClear) {
            config.clearConfig();
            success('Local configuration cleared');
        }

        console.log();
        console.log(boxen(
            chalk.green.bold('✓ Cleanup Initiated') + '\n\n' +
            chalk.gray('Resource group deletion is running in the background.') + '\n' +
            chalk.gray('This may take several minutes to complete.') + '\n\n' +
            chalk.gray('Check status with:') + '\n' +
            chalk.white(`az group show --name ${cfg.resourceGroup}`),
            { padding: 1, borderStyle: 'round', borderColor: 'green' }
        ));

    } catch (err) {
        error(`Cleanup failed: ${err.message}`);
    }
}

// Quick delete subcommand for specific resources
cleanupCommand
    .command('extension')
    .description('Delete only the Video Indexer extension')
    .option('--yes', 'Skip confirmation')
    .action(async (options) => {
        const cfg = config.getConfig();
        
        if (!options.yes) {
            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: `Delete extension ${cfg.viExtensionName}?`,
                initial: false
            });
            
            if (!confirmed) {
                info('Cancelled');
                return;
            }
        }

        await cleanupExtensionOnly(cfg);
    });

cleanupCommand
    .command('arc')
    .description('Disconnect from Azure Arc')
    .option('--yes', 'Skip confirmation')
    .action(async (options) => {
        const cfg = config.getConfig();
        
        if (!options.yes) {
            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: `Disconnect ${cfg.connectedClusterName} from Azure Arc?`,
                initial: false
            });
            
            if (!confirmed) {
                info('Cancelled');
                return;
            }
        }

        try {
            await withSpinner('Disconnecting from Azure Arc...', async () => {
                await az([
                    'connectedk8s', 'delete',
                    '--name', cfg.connectedClusterName,
                    '--resource-group', cfg.resourceGroup,
                    '--yes'
                ], { json: false });
            });

            config.updateSetupStatus('arcConnection', false);
            success('Disconnected from Azure Arc');
        } catch (err) {
            error(`Failed to disconnect: ${err.message}`);
        }
    });
