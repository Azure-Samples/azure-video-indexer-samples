/**
 * Extension command - Video Indexer Arc extension management
 */

import { Command } from 'commander';
import { prompt } from 'enquirer';
import chalk from 'chalk';
import boxen from 'boxen';
import Table from 'cli-table3';
import figures from 'figures';

import * as config from '../utils/config.js';
import { az, kubectl, withSpinner, success, error, warn, info, stepHeader, formatDuration } from '../utils/exec.js';

export const extensionCommand = new Command('extension')
    .description('Video Indexer Arc extension management');

// Install extension
extensionCommand
    .command('install')
    .description('Deploy Video Indexer Arc extension')
    .option('--advanced', 'Use advanced configuration with GPU summarization')
    .action(async (options) => {
        const cfg = config.getConfig();
        validateConfig(cfg);
        validateViConfig(cfg);
        
        stepHeader(9, 'Deploy Video Indexer Arc Extension');
        console.log(chalk.gray('This may take 5-15 minutes...'));
        console.log();

        const startTime = Date.now();

        try {
            // Check if extension already exists
            const exists = await extensionExists(cfg);
            if (exists) {
                warn(`Extension ${cfg.viExtensionName} already exists`);
                
                const { action } = await prompt({
                    type: 'select',
                    name: 'action',
                    message: 'What would you like to do?',
                    choices: [
                        { name: 'Update the extension', value: 'update' },
                        { name: 'Delete and recreate', value: 'recreate' },
                        { name: 'Cancel', value: 'cancel' }
                    ]
                });

                if (action === 'cancel') {
                    return;
                } else if (action === 'recreate') {
                    await deleteExtension(cfg);
                } else if (action === 'update') {
                    await updateExtension(cfg, options.advanced);
                    return;
                }
            }

            // Create extension
            await createExtension(cfg, options.advanced);

            config.updateSetupStatus('viExtension', true);
            
            const duration = formatDuration(Date.now() - startTime);
            
            console.log();
            console.log(boxen(
                chalk.green.bold('✓ Video Indexer Extension Deployed!') + '\n\n' +
                chalk.gray('Duration: ') + chalk.white(duration) + '\n\n' +
                chalk.gray('Endpoint URI: ') + chalk.cyan(cfg.viEndpointUri) + '\n' +
                chalk.gray('Extension: ') + chalk.white(cfg.viExtensionName) + '\n' +
                chalk.gray('Version: ') + chalk.white(cfg.viExtensionVersion),
                { padding: 1, borderStyle: 'round', borderColor: 'green' }
            ));

            console.log();
            info('Verify the installation with: ' + chalk.white('vi-arc extension status'));

        } catch (err) {
            error(`Failed to deploy extension: ${err.message}`);
            process.exit(1);
        }
    });

// Update extension
extensionCommand
    .command('update')
    .description('Update Video Indexer Arc extension')
    .option('--version <version>', 'New extension version')
    .action(async (options) => {
        const cfg = config.getConfig();
        validateConfig(cfg);

        if (options.version) {
            config.set('viExtensionVersion', options.version);
        }

        try {
            await updateExtension(cfg, false);
            success('Extension updated successfully');
        } catch (err) {
            error(`Failed to update extension: ${err.message}`);
            process.exit(1);
        }
    });

// Delete extension
extensionCommand
    .command('delete')
    .description('Delete Video Indexer Arc extension')
    .option('--yes', 'Skip confirmation')
    .action(async (options) => {
        const cfg = config.getConfig();
        validateConfig(cfg);

        if (!options.yes) {
            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: `Are you sure you want to delete extension ${cfg.viExtensionName}?`,
                initial: false
            });

            if (!confirmed) {
                info('Deletion cancelled');
                return;
            }
        }

        try {
            await deleteExtension(cfg);
            config.updateSetupStatus('viExtension', false);
            success('Extension deleted successfully');
        } catch (err) {
            error(`Failed to delete extension: ${err.message}`);
            process.exit(1);
        }
    });

// Show extension status
extensionCommand
    .command('status')
    .description('Show Video Indexer Arc extension status')
    .action(async () => {
        const cfg = config.getConfig();
        validateConfig(cfg);

        console.log(chalk.cyan.bold('Video Indexer Extension Status'));
        console.log();

        try {
            // Get extension info
            const extInfo = await withSpinner('Fetching extension status...', async () => {
                return await az([
                    'k8s-extension', 'show',
                    '--name', cfg.viExtensionName,
                    '--cluster-name', cfg.connectedClusterName,
                    '--resource-group', cfg.resourceGroup,
                    '--cluster-type', 'connectedClusters'
                ]);
            });

            const table = new Table({
                style: { head: [], border: [] },
                colWidths: [25, 50]
            });

            table.push(
                [chalk.gray('Name'), extInfo.name],
                [chalk.gray('Version'), extInfo.version || 'N/A'],
                [chalk.gray('Provisioning State'), getStatusColor(extInfo.provisioningState)],
                [chalk.gray('Release Train'), extInfo.releaseTrain || 'N/A'],
                [chalk.gray('Scope'), extInfo.scope?.cluster?.releaseNamespace || 'N/A'],
                [chalk.gray('Auto Upgrade'), extInfo.autoUpgradeMinorVersion ? 'Enabled' : 'Disabled']
            );

            console.log(table.toString());
            console.log();

            // Get pods in video-indexer namespace
            console.log(chalk.cyan.bold('Pods in video-indexer namespace:'));
            console.log();
            
            try {
                const podsOutput = await kubectl([
                    'get', 'pods',
                    '-n', 'video-indexer',
                    '--context', cfg.kubectlContext,
                    '-o', 'wide'
                ]);
                console.log(podsOutput);
            } catch {
                warn('Could not fetch pods. Namespace may not exist yet.');
            }

            // Show any error statuses
            if (extInfo.statuses && extInfo.statuses.length > 0) {
                console.log();
                console.log(chalk.cyan.bold('Extension Statuses:'));
                console.log();
                for (const status of extInfo.statuses) {
                    const icon = status.code === 'Ready' ? figures.tick : figures.warning;
                    const color = status.code === 'Ready' ? chalk.green : chalk.yellow;
                    console.log(`  ${color(icon)} ${status.displayStatus}: ${status.message || ''}`);
                }
            }

        } catch (err) {
            error(`Extension not found or error fetching status: ${err.message}`);
            info('The extension may not be installed. Run "vi-arc extension install" to deploy it.');
        }
    });

// Show extension configuration
extensionCommand
    .command('show-config')
    .description('Show current extension configuration')
    .action(async () => {
        const cfg = config.getConfig();

        console.log(chalk.cyan.bold('Extension Configuration'));
        console.log();

        const table = new Table({
            head: [chalk.cyan('Parameter'), chalk.cyan('Value')],
            style: { head: [], border: [] },
            colWidths: [40, 50]
        });

        table.push(
            ['videoIndexer.accountId', cfg.viAccountId || chalk.yellow('Not set')],
            ['videoIndexer.accountResourceId', truncate(cfg.viAccountResourceId, 45) || chalk.yellow('Not set')],
            ['videoIndexer.endpointUri', cfg.viEndpointUri || chalk.yellow('Not set')],
            ['videoIndexer.mediaUploadsEnabled', String(cfg.viMediaUploadsEnabled)],
            ['videoIndexer.liveVideoStreamEnabled', String(cfg.viLiveVideoEnabled)],
            ['ViAi.LiveSummarization.enabled', String(cfg.viLiveSummarizationEnabled)],
            ['ViAi.gpu.enabled', String(cfg.viGpuSummarization)],
            ['ViAi.deepstream.nodeSelector.workload', cfg.viDeepstreamNodeSelector],
            ['ViAi.summarization.nodeSelector.workload', cfg.viSummarizationNodeSelector],
            ['Extension Version', cfg.viExtensionVersion || chalk.yellow('Not set')],
            ['Release Train', cfg.viReleaseTrain]
        );

        console.log(table.toString());
        console.log();
        
        console.log(chalk.gray('Configuration Reference:'));
        console.log();
        
        const refTable = new Table({
            head: [chalk.cyan('Parameter'), chalk.cyan('Description'), chalk.cyan('Required')],
            style: { head: [], border: [] }
        });

        refTable.push(
            ['accountId', 'Video Indexer account GUID', 'Yes'],
            ['accountResourceId', 'Full ARM resource ID', 'Yes'],
            ['endpointUri', 'Public endpoint URI', 'Yes'],
            ['mediaUploadsEnabled', 'Enable media uploads', 'No (default: true)'],
            ['liveVideoStreamEnabled', 'Enable live video', 'No (default: false)'],
            ['LiveSummarization.enabled', 'Enable live summarization', 'No (default: false)'],
            ['gpu.enabled', 'Use GPU for summarization', 'No (default: false)']
        );

        console.log(refTable.toString());
    });

async function extensionExists(cfg) {
    try {
        await az([
            'k8s-extension', 'show',
            '--name', cfg.viExtensionName,
            '--cluster-name', cfg.connectedClusterName,
            '--resource-group', cfg.resourceGroup,
            '--cluster-type', 'connectedClusters'
        ]);
        return true;
    } catch {
        return false;
    }
}

async function createExtension(cfg, advanced = false) {
    const args = [
        'k8s-extension', 'create',
        '--name', cfg.viExtensionName,
        '--extension-type', 'Microsoft.videoIndexer',
        '--scope', 'cluster',
        '--release-namespace', 'video-indexer',
        '--cluster-name', cfg.connectedClusterName,
        '--resource-group', cfg.resourceGroup,
        '--cluster-type', 'connectedClusters',
        '--version', cfg.viExtensionVersion,
        '--release-train', cfg.viReleaseTrain,
        '--auto-upgrade-minor-version', 'false',
        '--config', `videoIndexer.accountId=${cfg.viAccountId}`,
        '--config', `videoIndexer.accountResourceId=${cfg.viAccountResourceId}`,
        '--config', `videoIndexer.endpointUri=${cfg.viEndpointUri}`,
        '--config', `videoIndexer.mediaUploadsEnabled=${cfg.viMediaUploadsEnabled}`,
        '--config', `videoIndexer.liveVideoStreamEnabled=${cfg.viLiveVideoEnabled}`,
        '--config', `ViAi.LiveSummarization.enabled=${cfg.viLiveSummarizationEnabled}`,
        '--config', `ViAi.gpu.enabled=${cfg.viGpuSummarization}`,
        '--config', `ViAi.gpu.tolerations.key=${cfg.viGpuTolerationsKey}`,
        '--config', `ViAi.deepstream.nodeSelector.workload=${cfg.viDeepstreamNodeSelector}`,
        '--config', 'storage.storageClass=azurefile-csi-premium',
        '--config', 'storage.accessMode=ReadWriteMany'
    ];

    // Add summarization node selector for advanced config
    if (advanced || cfg.viGpuSummarization) {
        args.push('--config', `ViAi.summarization.nodeSelector.workload=${cfg.viSummarizationNodeSelector}`);
    }

    await withSpinner('Creating Video Indexer extension...', async () => {
        await az(args);
    });

    // Wait for extension to be ready
    await withSpinner('Waiting for extension to provision...', async () => {
        let attempts = 0;
        const maxAttempts = 60; // 10 minutes with 10s intervals
        
        while (attempts < maxAttempts) {
            try {
                const result = await az([
                    'k8s-extension', 'show',
                    '--name', cfg.viExtensionName,
                    '--cluster-name', cfg.connectedClusterName,
                    '--resource-group', cfg.resourceGroup,
                    '--cluster-type', 'connectedClusters',
                    '--query', 'provisioningState',
                    '-o', 'tsv'
                ], { json: false });

                const state = result.trim();
                if (state === 'Succeeded') {
                    return;
                } else if (state === 'Failed') {
                    throw new Error('Extension provisioning failed');
                }
            } catch (err) {
                if (err.message.includes('Extension provisioning failed')) {
                    throw err;
                }
            }
            
            await new Promise(resolve => setTimeout(resolve, 10000));
            attempts++;
        }
        
        throw new Error('Extension provisioning timed out');
    });

    success('Video Indexer extension created');
}

async function updateExtension(cfg, advanced = false) {
    const args = [
        'k8s-extension', 'update',
        '--name', cfg.viExtensionName,
        '--cluster-name', cfg.connectedClusterName,
        '--resource-group', cfg.resourceGroup,
        '--cluster-type', 'connectedClusters',
        '--version', cfg.viExtensionVersion,
        '--release-train', cfg.viReleaseTrain,
        '--auto-upgrade-minor-version', 'false',
        '--config', `videoIndexer.accountId=${cfg.viAccountId}`,
        '--config', `videoIndexer.accountResourceId=${cfg.viAccountResourceId}`,
        '--config', `videoIndexer.endpointUri=${cfg.viEndpointUri}`,
        '--config', `videoIndexer.mediaUploadsEnabled=${cfg.viMediaUploadsEnabled}`,
        '--config', `videoIndexer.liveVideoStreamEnabled=${cfg.viLiveVideoEnabled}`,
        '--config', `ViAi.LiveSummarization.enabled=${cfg.viLiveSummarizationEnabled}`,
        '--config', `ViAi.gpu.enabled=${cfg.viGpuSummarization}`,
        '--config', `ViAi.gpu.tolerations.key=${cfg.viGpuTolerationsKey}`,
        '--config', 'storage.storageClass=azurefile-csi-premium',
        '--yes'
    ];

    await withSpinner('Updating Video Indexer extension...', async () => {
        await az(args);
    });

    success('Extension updated');
}

async function deleteExtension(cfg) {
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
}

function validateConfig(cfg) {
    if (!cfg.subscriptionId || !cfg.region || !cfg.resourcesPrefix) {
        error('Configuration not initialized. Run "vi-arc setup" first.');
        process.exit(1);
    }
    
    if (!cfg.connectedClusterName) {
        error('Arc connected cluster not configured. Run cluster setup first.');
        process.exit(1);
    }
}

function validateViConfig(cfg) {
    if (!cfg.viAccountId || !cfg.viAccountResourceId) {
        error('Video Indexer account not configured.');
        info('Run "vi-arc setup" or configure manually:');
        console.log(chalk.gray('  vi-arc config set viAccountId <your-account-id>'));
        console.log(chalk.gray('  vi-arc config set viAccountResourceId <your-resource-id>'));
        process.exit(1);
    }

    if (!cfg.viExtensionVersion) {
        error('Extension version not set.');
        info('Set it with: vi-arc config set viExtensionVersion <version>');
        process.exit(1);
    }
}

function getStatusColor(status) {
    switch (status) {
        case 'Succeeded':
            return chalk.green(status);
        case 'Failed':
            return chalk.red(status);
        case 'Creating':
        case 'Updating':
        case 'Deleting':
            return chalk.yellow(status);
        default:
            return chalk.gray(status);
    }
}

function truncate(str, length) {
    if (!str) return str;
    if (str.length <= length) return str;
    return str.substring(0, length - 3) + '...';
}
