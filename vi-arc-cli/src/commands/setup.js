/**
 * Setup command - Interactive configuration wizard
 */

import { Command } from 'commander';
import enquirer from 'enquirer';
const { prompt } = enquirer;
import chalk from 'chalk';
import boxen from 'boxen';
import Table from 'cli-table3';
import figures from 'figures';

import * as config from '../utils/config.js';
import {
    checkAzureCli,
    getCurrentSubscription,
    listSubscriptions,
    setSubscription,
    listVideoIndexerAccounts,
    checkGpuQuota,
    getGpuRegions
} from '../utils/azure.js';
import { withSpinner, success, error, warn, info, commandExists } from '../utils/exec.js';

export const setupCommand = new Command('setup')
    .description('Interactive setup wizard to configure Video Indexer Arc deployment')
    .option('--reset', 'Reset existing configuration and start fresh')
    .action(async (options) => {
        try {
            if (options.reset) {
                config.clearConfig();
                success('Configuration reset');
            }

            console.log(boxen(
                chalk.bold('Setup Wizard') + '\n\n' +
                chalk.gray('This wizard will help you configure the deployment.\n') +
                chalk.gray('Values will be auto-detected from Azure CLI when possible.'),
                { padding: 1, borderStyle: 'round', borderColor: 'blue' }
            ));

            // Step 1: Check prerequisites
            console.log();
            console.log(chalk.cyan.bold(`${figures.pointer} Checking prerequisites...`));
            console.log();

            await checkPrerequisites();

            // Step 2: Azure subscription
            console.log();
            console.log(chalk.cyan.bold(`${figures.pointer} Azure Configuration`));
            console.log();

            const subscription = await selectSubscription();
            
            // Step 3: Region selection
            const region = await selectRegion();
            
            // Step 4: Check GPU quota
            console.log();
            console.log(chalk.cyan.bold(`${figures.pointer} Checking GPU Quota`));
            console.log();
            
            await checkAndDisplayGpuQuota(region);
            
            // Step 5: Resource naming
            console.log();
            console.log(chalk.cyan.bold(`${figures.pointer} Resource Naming`));
            console.log();

            const prefix = await getResourcePrefix();
            
            // Initialize config with gathered values
            config.initializeConfig(prefix, region, subscription.id);
            
            // Step 6: VM Sizes
            console.log();
            console.log(chalk.cyan.bold(`${figures.pointer} VM Configuration`));
            console.log();
            
            await configureVmSizes();
            
            // Step 7: Video Indexer Account
            console.log();
            console.log(chalk.cyan.bold(`${figures.pointer} Video Indexer Account`));
            console.log();
            
            await configureVideoIndexerAccount();
            
            // Step 8: Feature flags
            console.log();
            console.log(chalk.cyan.bold(`${figures.pointer} Feature Configuration`));
            console.log();
            
            await configureFeatures();
            
            // Display summary
            displayConfigSummary();
            
            // Confirm configuration
            const { confirmed } = await prompt({
                type: 'confirm',
                name: 'confirmed',
                message: 'Save this configuration?',
                initial: true
            });
            
            if (confirmed) {
                config.updateSetupStatus('prerequisites', true);
                success('Configuration saved successfully!');
                console.log();
                info(`Configuration file: ${config.getConfigPath()}`);
                console.log();
                console.log(chalk.cyan('Next steps:'));
                console.log(chalk.gray('  1. Run ') + chalk.white('vi-arc cluster create') + chalk.gray(' to create the AKS cluster'));
                console.log(chalk.gray('  2. Run ') + chalk.white('vi-arc cluster nodepools') + chalk.gray(' to add node pools'));
                console.log(chalk.gray('  3. Run ') + chalk.white('vi-arc extension install') + chalk.gray(' to deploy Video Indexer'));
                console.log();
                console.log(chalk.gray('Or run ') + chalk.white('vi-arc cluster deploy') + chalk.gray(' for a full automated deployment'));
            } else {
                warn('Configuration not saved');
            }

        } catch (err) {
            if (err.message !== 'cancelled') {
                error(`Setup failed: ${err.message}`);
            }
            process.exit(1);
        }
    });

async function checkPrerequisites() {
    const checks = [
        { name: 'Azure CLI (az)', command: 'az' },
        { name: 'kubectl', command: 'kubectl' },
        { name: 'Helm', command: 'helm' }
    ];

    const table = new Table({
        head: [chalk.cyan('Tool'), chalk.cyan('Status')],
        style: { head: [], border: [] }
    });

    let allPassed = true;

    for (const check of checks) {
        const exists = await commandExists(check.command);
        if (exists) {
            table.push([check.name, chalk.green(`${figures.tick} Installed`)]);
        } else {
            table.push([check.name, chalk.red(`${figures.cross} Not found`)]);
            allPassed = false;
        }
    }

    // Check Azure CLI login
    const azStatus = await checkAzureCli();
    if (azStatus.installed && azStatus.loggedIn) {
        table.push(['Azure CLI Login', chalk.green(`${figures.tick} Logged in`)]);
    } else if (azStatus.installed) {
        table.push(['Azure CLI Login', chalk.red(`${figures.cross} Not logged in`)]);
        allPassed = false;
    }

    console.log(table.toString());
    console.log();

    if (!allPassed) {
        error('Some prerequisites are missing. Please install them before continuing.');
        console.log();
        console.log(chalk.gray('Installation instructions:'));
        console.log(chalk.gray('  Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli'));
        console.log(chalk.gray('  kubectl: https://kubernetes.io/docs/tasks/tools/'));
        console.log(chalk.gray('  Helm: https://helm.sh/docs/intro/install/'));
        console.log();
        
        const { continueAnyway } = await prompt({
            type: 'confirm',
            name: 'continueAnyway',
            message: 'Continue anyway?',
            initial: false
        });
        
        if (!continueAnyway) {
            throw new Error('cancelled');
        }
    } else {
        success('All prerequisites are installed');
    }
}

async function selectSubscription() {
    const subscriptions = await withSpinner('Fetching Azure subscriptions...', async () => {
        return await listSubscriptions();
    });

    if (subscriptions.length === 0) {
        throw new Error('No Azure subscriptions found. Please login with: az login');
    }

    const currentSub = await getCurrentSubscription();
    
    const choices = subscriptions.map(sub => ({
        name: `${sub.name} (${sub.id})${sub.isDefault ? ' [current]' : ''}`,
        value: sub.id
    }));

    const { subscriptionId } = await prompt({
        type: 'select',
        name: 'subscriptionId',
        message: 'Select Azure subscription:',
        choices,
        initial: choices.findIndex(c => c.value === currentSub.id)
    });

    const selectedSub = subscriptions.find(s => s.id === subscriptionId);
    
    if (subscriptionId !== currentSub.id) {
        await withSpinner('Setting subscription...', async () => {
            await setSubscription(subscriptionId);
        });
    }

    success(`Using subscription: ${selectedSub.name}`);
    return selectedSub;
}

async function selectRegion() {
    const gpuRegions = getGpuRegions();
    
    const choices = gpuRegions.map(region => ({
        name: region,
        value: region
    }));

    const { region } = await prompt({
        type: 'autocomplete',
        name: 'region',
        message: 'Select Azure region (GPU-capable regions):',
        choices,
        initial: 0
    });

    success(`Using region: ${region}`);
    return region;
}

async function checkAndDisplayGpuQuota(region) {
    const gpuTypes = ['H100', 'A100', 'A10'];
    
    const table = new Table({
        head: [chalk.cyan('GPU Type'), chalk.cyan('Current'), chalk.cyan('Limit'), chalk.cyan('Status')],
        style: { head: [], border: [] }
    });

    for (const gpuType of gpuTypes) {
        const quota = await withSpinner(`Checking ${gpuType} quota...`, async () => {
            return await checkGpuQuota(region, gpuType);
        });

        const status = quota.limit > 0 
            ? (quota.available ? chalk.green(`${figures.tick} Available`) : chalk.yellow(`${figures.warning} In use`))
            : chalk.red(`${figures.cross} No quota`);
        
        table.push([
            quota.name || gpuType,
            quota.currentUsage.toString(),
            quota.limit.toString(),
            status
        ]);
    }

    console.log(table.toString());
    console.log();
    
    info('If you need GPU quota, request it at: https://portal.azure.com → Quotas');
}

async function getResourcePrefix() {
    const { prefix } = await prompt({
        type: 'input',
        name: 'prefix',
        message: 'Enter resource naming prefix:',
        initial: 'vi-arc',
        validate: (value) => {
            if (!value || value.length < 3) {
                return 'Prefix must be at least 3 characters';
            }
            if (!/^[a-z][a-z0-9-]*$/.test(value)) {
                return 'Prefix must start with a letter and contain only lowercase letters, numbers, and hyphens';
            }
            if (value.length > 20) {
                return 'Prefix must be 20 characters or less';
            }
            return true;
        }
    });

    return prefix;
}

async function configureVmSizes() {
    const vmSizes = config.getDefaultVmSizes();
    const gpuOptions = config.getGpuVmOptions();

    // GPU VM selection
    const { gpuVm } = await prompt({
        type: 'select',
        name: 'gpuVm',
        message: 'Select GPU VM size:',
        choices: gpuOptions.map(opt => ({
            name: `${opt.name} - ${opt.description}`,
            value: opt.value
        })),
        initial: 0
    });

    config.set('gpuVmSize', gpuVm);
    
    // Advanced VM configuration
    const { configureAdvanced } = await prompt({
        type: 'confirm',
        name: 'configureAdvanced',
        message: 'Configure advanced VM sizes?',
        initial: false
    });

    if (configureAdvanced) {
        const { nodeVmSize } = await prompt({
            type: 'input',
            name: 'nodeVmSize',
            message: 'System node VM size:',
            initial: vmSizes.system
        });
        config.set('nodeVmSize', nodeVmSize);

        const { workerVmSize } = await prompt({
            type: 'input',
            name: 'workerVmSize',
            message: 'Worker node VM size:',
            initial: vmSizes.worker
        });
        config.set('workerVmSize', workerVmSize);
    }

    success('VM configuration saved');
}

async function configureVideoIndexerAccount() {
    const accounts = await withSpinner('Fetching Video Indexer accounts...', async () => {
        return await listVideoIndexerAccounts();
    });

    if (accounts.length === 0) {
        warn('No Video Indexer accounts found in this subscription');
        console.log(chalk.gray('You can create one at: https://portal.azure.com'));
        console.log();
        
        const { manual } = await prompt({
            type: 'confirm',
            name: 'manual',
            message: 'Enter Video Indexer account details manually?',
            initial: true
        });

        if (manual) {
            const { accountId } = await prompt({
                type: 'input',
                name: 'accountId',
                message: 'Video Indexer Account ID (GUID):',
                validate: (value) => {
                    if (!value || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) {
                        return 'Please enter a valid GUID';
                    }
                    return true;
                }
            });
            config.set('viAccountId', accountId);

            const { resourceId } = await prompt({
                type: 'input',
                name: 'resourceId',
                message: 'Video Indexer Resource ID:',
                validate: (value) => {
                    if (!value || !value.startsWith('/subscriptions/')) {
                        return 'Please enter a valid ARM resource ID';
                    }
                    return true;
                }
            });
            config.set('viAccountResourceId', resourceId);
        }
    } else {
        const choices = accounts.map(acc => ({
            name: `${acc.name} (${acc.resourceGroup}) - ${acc.location}`,
            value: acc
        }));

        const { account } = await prompt({
            type: 'select',
            name: 'account',
            message: 'Select Video Indexer account:',
            choices
        });

        config.set('viAccountId', account.accountId);
        config.set('viAccountResourceId', account.resourceId);
        success(`Using Video Indexer account: ${account.name}`);
    }

    // Extension version
    const { version } = await prompt({
        type: 'input',
        name: 'version',
        message: 'Video Indexer extension version:',
        initial: '1.2.53'
    });
    config.set('viExtensionVersion', version);
}

async function configureFeatures() {
    const { features } = await prompt({
        type: 'multiselect',
        name: 'features',
        message: 'Enable features:',
        choices: [
            { name: 'Live Video Streaming', value: 'liveVideo', enabled: true },
            { name: 'Media Uploads', value: 'mediaUploads', enabled: true },
            { name: 'Live Summarization', value: 'liveSummarization' },
            { name: 'GPU Summarization', value: 'gpuSummarization' },
            { name: 'CPU Summarization Node Pool', value: 'cpuSummarization' }
        ],
        initial: ['liveVideo', 'mediaUploads']
    });

    config.set('viLiveVideoEnabled', features.includes('liveVideo'));
    config.set('viMediaUploadsEnabled', features.includes('mediaUploads'));
    config.set('viLiveSummarizationEnabled', features.includes('liveSummarization'));
    config.set('viGpuSummarization', features.includes('gpuSummarization'));
    config.set('enableSummarizationGpu', features.includes('gpuSummarization'));
    config.set('enableSummarizationCpu', features.includes('cpuSummarization'));

    success('Features configured');
}

function displayConfigSummary() {
    console.log();
    console.log(boxen(
        chalk.bold.cyan('Configuration Summary'),
        { padding: { left: 2, right: 2 }, borderStyle: 'round', borderColor: 'cyan' }
    ));
    console.log();

    const cfg = config.getConfig();
    
    const table = new Table({
        style: { head: [], border: [] },
        colWidths: [30, 50]
    });

    table.push(
        [chalk.gray('Subscription ID'), cfg.subscriptionId],
        [chalk.gray('Region'), cfg.region],
        [chalk.gray('Resource Group'), cfg.resourceGroup],
        [chalk.gray('AKS Cluster'), cfg.aksClusterName],
        [chalk.gray('Arc Connected Cluster'), cfg.connectedClusterName],
        [chalk.gray('DNS Label'), cfg.dnsLabel],
        [chalk.gray('Endpoint URI'), cfg.viEndpointUri],
        ['', ''],
        [chalk.gray('GPU VM Size'), cfg.gpuVmSize],
        [chalk.gray('Worker VM Size'), cfg.workerVmSize],
        ['', ''],
        [chalk.gray('VI Account ID'), cfg.viAccountId || chalk.yellow('Not set')],
        [chalk.gray('VI Extension Version'), cfg.viExtensionVersion],
        ['', ''],
        [chalk.gray('Live Video'), cfg.viLiveVideoEnabled ? chalk.green('Enabled') : chalk.gray('Disabled')],
        [chalk.gray('Media Uploads'), cfg.viMediaUploadsEnabled ? chalk.green('Enabled') : chalk.gray('Disabled')],
        [chalk.gray('GPU Summarization'), cfg.viGpuSummarization ? chalk.green('Enabled') : chalk.gray('Disabled')]
    );

    console.log(table.toString());
    console.log();
}
