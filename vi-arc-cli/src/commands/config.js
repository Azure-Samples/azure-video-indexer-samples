/**
 * Config command - Configuration management
 */

import { Command } from 'commander';
import enquirer from 'enquirer';
const { prompt } = enquirer;
import chalk from 'chalk';
import boxen from 'boxen';
import Table from 'cli-table3';
import { writeFileSync, readFileSync } from 'fs';

import * as config from '../utils/config.js';
import { success, error, info, warn } from '../utils/exec.js';

export const configCommand = new Command('config')
    .description('Manage CLI configuration');

// Show all configuration
configCommand
    .command('show')
    .description('Display current configuration')
    .option('--json', 'Output as JSON')
    .action(async (options) => {
        const cfg = config.getConfig();

        if (options.json) {
            console.log(JSON.stringify(cfg, null, 2));
            return;
        }

        if (!cfg.resourcesPrefix) {
            warn('No configuration found. Run "vi-arc setup" to initialize.');
            return;
        }

        console.log(chalk.cyan.bold('Current Configuration'));
        console.log();

        // Azure Configuration
        console.log(chalk.cyan.bold('Azure Configuration:'));
        const azureTable = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 55]
        });
        azureTable.push(
            [chalk.gray('Subscription ID'), cfg.subscriptionId || chalk.yellow('Not set')],
            [chalk.gray('Region'), cfg.region || chalk.yellow('Not set')],
            [chalk.gray('Resource Prefix'), cfg.resourcesPrefix || chalk.yellow('Not set')],
            [chalk.gray('Random Suffix'), cfg.randomSuffix || chalk.yellow('Not set')]
        );
        console.log(azureTable.toString());
        console.log();

        // Resource Names
        console.log(chalk.cyan.bold('Resource Names:'));
        const resourceTable = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 55]
        });
        resourceTable.push(
            [chalk.gray('Resource Group'), cfg.resourceGroup || chalk.yellow('Not set')],
            [chalk.gray('AKS Cluster'), cfg.aksClusterName || chalk.yellow('Not set')],
            [chalk.gray('Arc Connected Cluster'), cfg.connectedClusterName || chalk.yellow('Not set')],
            [chalk.gray('Node Pool RG'), cfg.nodePoolResourceGroup || chalk.yellow('Not set')],
            [chalk.gray('DNS Label'), cfg.dnsLabel || chalk.yellow('Not set')],
            [chalk.gray('kubectl Context'), cfg.kubectlContext || chalk.yellow('Not set')]
        );
        console.log(resourceTable.toString());
        console.log();

        // VM Configuration
        console.log(chalk.cyan.bold('VM Configuration:'));
        const vmTable = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 55]
        });
        vmTable.push(
            [chalk.gray('System Node VM'), cfg.nodeVmSize || 'Standard_D4a_v4'],
            [chalk.gray('Worker Node VM'), cfg.workerVmSize || 'Standard_D32a_v4'],
            [chalk.gray('GPU VM'), cfg.gpuVmSize || 'Standard_NC40ads_H100_v5'],
            [chalk.gray('CPU Summarization VM'), cfg.summarizationCpuVm || 'Standard_F32s_v2']
        );
        console.log(vmTable.toString());
        console.log();

        // Video Indexer Configuration
        console.log(chalk.cyan.bold('Video Indexer Configuration:'));
        const viTable = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 55]
        });
        viTable.push(
            [chalk.gray('Extension Name'), cfg.viExtensionName || 'video-indexer'],
            [chalk.gray('Extension Version'), cfg.viExtensionVersion || chalk.yellow('Not set')],
            [chalk.gray('Release Train'), cfg.viReleaseTrain || 'preview'],
            [chalk.gray('Account ID'), cfg.viAccountId || chalk.yellow('Not set')],
            [chalk.gray('Endpoint URI'), cfg.viEndpointUri || chalk.yellow('Not set')],
            [chalk.gray('Live Video'), cfg.viLiveVideoEnabled ? chalk.green('Enabled') : chalk.gray('Disabled')],
            [chalk.gray('Media Uploads'), cfg.viMediaUploadsEnabled ? chalk.green('Enabled') : chalk.gray('Disabled')],
            [chalk.gray('GPU Summarization'), cfg.viGpuSummarization ? chalk.green('Enabled') : chalk.gray('Disabled')]
        );
        console.log(viTable.toString());
        console.log();

        // Setup Status
        console.log(chalk.cyan.bold('Setup Status:'));
        const status = config.getSetupStatus();
        const statusTable = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 15]
        });
        
        const steps = [
            ['Prerequisites', 'prerequisites'],
            ['Resource Group', 'resourceGroup'],
            ['AKS Cluster', 'aksCluster'],
            ['Node Pools', 'nodePools'],
            ['GPU Operator', 'gpuOperator'],
            ['Ingress', 'ingress'],
            ['Arc Connection', 'arcConnection'],
            ['Cert Manager', 'certManager'],
            ['VI Extension', 'viExtension']
        ];

        for (const [name, key] of steps) {
            const completed = status[key];
            statusTable.push([
                chalk.gray(name),
                completed ? chalk.green('✓ Complete') : chalk.gray('○ Pending')
            ]);
        }
        console.log(statusTable.toString());
        console.log();

        info(`Configuration file: ${config.getConfigPath()}`);
    });

// Get a specific configuration value
configCommand
    .command('get <key>')
    .description('Get a specific configuration value')
    .action((key) => {
        const value = config.get(key);
        if (value !== undefined) {
            console.log(value);
        } else {
            error(`Configuration key "${key}" not found`);
            process.exit(1);
        }
    });

// Set a configuration value
configCommand
    .command('set <key> <value>')
    .description('Set a configuration value')
    .action((key, value) => {
        // Handle boolean values
        if (value === 'true') value = true;
        else if (value === 'false') value = false;
        
        config.set(key, value);
        success(`Set ${key} = ${value}`);
    });

// Reset configuration
configCommand
    .command('reset')
    .description('Reset all configuration')
    .option('--yes', 'Skip confirmation')
    .action(async (options) => {
        if (!options.yes) {
            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: 'Are you sure you want to reset all configuration?',
                initial: false
            });

            if (!confirmed) {
                info('Reset cancelled');
                return;
            }
        }

        config.clearConfig();
        success('Configuration reset');
    });

// Export configuration
configCommand
    .command('export [file]')
    .description('Export configuration to a file')
    .action((file) => {
        const cfg = config.getConfig();
        const json = JSON.stringify(cfg, null, 2);
        
        if (file) {
            writeFileSync(file, json);
            success(`Configuration exported to ${file}`);
        } else {
            console.log(json);
        }
    });

// Import configuration
configCommand
    .command('import <file>')
    .description('Import configuration from a file')
    .option('--merge', 'Merge with existing configuration')
    .action(async (file, options) => {
        try {
            const json = readFileSync(file, 'utf-8');
            const imported = JSON.parse(json);

            if (!options.merge) {
                const { confirmed } = await prompt({
                    type: 'confirm',
                    name: 'confirmed',
                    message: 'This will replace your current configuration. Continue?',
                    initial: true
                });

                if (!confirmed) {
                    info('Import cancelled');
                    return;
                }

                config.clearConfig();
            }

            config.importConfig(json);
            success(`Configuration imported from ${file}`);
        } catch (err) {
            error(`Failed to import configuration: ${err.message}`);
            process.exit(1);
        }
    });

// Show configuration file path
configCommand
    .command('path')
    .description('Show configuration file path')
    .action(() => {
        console.log(config.getConfigPath());
    });

// Interactive configuration editor
configCommand
    .command('edit')
    .description('Interactively edit configuration')
    .action(async () => {
        const cfg = config.getConfig();

        const { section } = await prompt({
            type: 'select',
            name: 'section',
            message: 'Which section do you want to edit?',
            choices: [
                { name: 'Azure Configuration', value: 'azure' },
                { name: 'Resource Names', value: 'resources' },
                { name: 'VM Sizes', value: 'vm' },
                { name: 'Video Indexer', value: 'vi' },
                { name: 'Features', value: 'features' }
            ]
        });

        switch (section) {
            case 'azure':
                await editAzureConfig(cfg);
                break;
            case 'resources':
                await editResourceNames(cfg);
                break;
            case 'vm':
                await editVmSizes(cfg);
                break;
            case 'vi':
                await editViConfig(cfg);
                break;
            case 'features':
                await editFeatures(cfg);
                break;
        }

        success('Configuration updated');
    });

async function editAzureConfig(cfg) {
    const answers = await prompt([
        {
            type: 'input',
            name: 'subscriptionId',
            message: 'Subscription ID:',
            initial: cfg.subscriptionId
        },
        {
            type: 'input',
            name: 'region',
            message: 'Region:',
            initial: cfg.region
        },
        {
            type: 'input',
            name: 'resourcesPrefix',
            message: 'Resource Prefix:',
            initial: cfg.resourcesPrefix
        }
    ]);

    config.setMultiple(answers);
}

async function editResourceNames(cfg) {
    const answers = await prompt([
        {
            type: 'input',
            name: 'resourceGroup',
            message: 'Resource Group:',
            initial: cfg.resourceGroup
        },
        {
            type: 'input',
            name: 'aksClusterName',
            message: 'AKS Cluster Name:',
            initial: cfg.aksClusterName
        },
        {
            type: 'input',
            name: 'connectedClusterName',
            message: 'Arc Connected Cluster Name:',
            initial: cfg.connectedClusterName
        },
        {
            type: 'input',
            name: 'dnsLabel',
            message: 'DNS Label:',
            initial: cfg.dnsLabel
        }
    ]);

    config.setMultiple(answers);
}

async function editVmSizes(cfg) {
    const gpuOptions = config.getGpuVmOptions();
    
    const answers = await prompt([
        {
            type: 'input',
            name: 'nodeVmSize',
            message: 'System Node VM Size:',
            initial: cfg.nodeVmSize || 'Standard_D4a_v4'
        },
        {
            type: 'input',
            name: 'workerVmSize',
            message: 'Worker Node VM Size:',
            initial: cfg.workerVmSize || 'Standard_D32a_v4'
        },
        {
            type: 'select',
            name: 'gpuVmSize',
            message: 'GPU VM Size:',
            choices: gpuOptions.map(opt => ({
                name: `${opt.name} - ${opt.description}`,
                value: opt.value
            })),
            initial: gpuOptions.findIndex(opt => opt.value === cfg.gpuVmSize)
        },
        {
            type: 'input',
            name: 'summarizationCpuVm',
            message: 'CPU Summarization VM Size:',
            initial: cfg.summarizationCpuVm || 'Standard_F32s_v2'
        }
    ]);

    config.setMultiple(answers);
}

async function editViConfig(cfg) {
    const answers = await prompt([
        {
            type: 'input',
            name: 'viAccountId',
            message: 'Video Indexer Account ID:',
            initial: cfg.viAccountId
        },
        {
            type: 'input',
            name: 'viAccountResourceId',
            message: 'Video Indexer Resource ID:',
            initial: cfg.viAccountResourceId
        },
        {
            type: 'input',
            name: 'viExtensionVersion',
            message: 'Extension Version:',
            initial: cfg.viExtensionVersion || '1.2.53'
        },
        {
            type: 'select',
            name: 'viReleaseTrain',
            message: 'Release Train:',
            choices: ['preview', 'stable'],
            initial: cfg.viReleaseTrain === 'stable' ? 1 : 0
        },
        {
            type: 'input',
            name: 'viEndpointUri',
            message: 'Endpoint URI:',
            initial: cfg.viEndpointUri
        }
    ]);

    config.setMultiple(answers);
}

async function editFeatures(cfg) {
    const answers = await prompt([
        {
            type: 'confirm',
            name: 'viLiveVideoEnabled',
            message: 'Enable Live Video:',
            initial: cfg.viLiveVideoEnabled !== false
        },
        {
            type: 'confirm',
            name: 'viMediaUploadsEnabled',
            message: 'Enable Media Uploads:',
            initial: cfg.viMediaUploadsEnabled !== false
        },
        {
            type: 'confirm',
            name: 'viLiveSummarizationEnabled',
            message: 'Enable Live Summarization:',
            initial: cfg.viLiveSummarizationEnabled === true
        },
        {
            type: 'confirm',
            name: 'viGpuSummarization',
            message: 'Enable GPU Summarization:',
            initial: cfg.viGpuSummarization === true
        },
        {
            type: 'confirm',
            name: 'enableSummarizationGpu',
            message: 'Create GPU Summarization Node Pool:',
            initial: cfg.enableSummarizationGpu === true
        },
        {
            type: 'confirm',
            name: 'enableSummarizationCpu',
            message: 'Create CPU Summarization Node Pool:',
            initial: cfg.enableSummarizationCpu === true
        }
    ]);

    config.setMultiple(answers);
}
