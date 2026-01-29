/**
 * API command - Video Indexer Arc API operations
 */

import { Command } from 'commander';
import { prompt } from 'enquirer';
import chalk from 'chalk';
import boxen from 'boxen';
import Table from 'cli-table3';
import figures from 'figures';

import * as config from '../utils/config.js';
import { VideoIndexerClient } from '../utils/api-client.js';
import { withSpinner, success, error, warn, info } from '../utils/exec.js';
import {
    autoGenerateExtensionToken,
    getAzureAccessToken,
    getExtensionResourceId,
    generateExtensionAccessToken
} from '../utils/azure.js';

export const apiCommand = new Command('api')
    .description('Video Indexer Arc API operations');

// Authentication
apiCommand
    .command('auth')
    .description('Authenticate for API calls (auto-generates extension access token)')
    .option('--token <token>', 'Manually set JWT Bearer token')
    .option('--manual', 'Use manual token entry instead of auto-generation')
    .action(async (options) => {
        try {
            if (options.token) {
                // Manual token provided via option
                config.set('viApiToken', options.token);
                config.set('viApiTokenExpiry', null); // Clear expiry for manual tokens
                success('API token saved');
                info('Token will be used for all API calls');
                return;
            }

            if (options.manual) {
                // Manual token entry
                const response = await prompt({
                    type: 'password',
                    name: 'token',
                    message: 'Enter your JWT Bearer token:'
                });
                config.set('viApiToken', response.token);
                config.set('viApiTokenExpiry', null);
                success('API token saved');
                info('Token will be used for all API calls');
                return;
            }

            // Auto-generate extension access token
            console.log(boxen(
                chalk.cyan.bold('Auto-Generate Extension Access Token') + '\n\n' +
                chalk.gray('This will:') + '\n' +
                chalk.gray('  1. Get Azure access token via az cli') + '\n' +
                chalk.gray('  2. Call VI API to generate extension access token') + '\n' +
                chalk.gray('  3. Save the token for API calls') + '\n\n' +
                chalk.gray('Requires: az cli logged in, VI account configured'),
                { padding: 1, borderStyle: 'round', borderColor: 'cyan' }
            ));
            console.log();

            const cfg = config.getConfig();

            // Verify configuration
            if (!cfg.viAccountResourceId) {
                error('Video Indexer account not configured');
                info('Run "vi-arc setup" to configure your VI account');
                process.exit(1);
            }

            if (!cfg.connectedClusterName || !cfg.resourceGroup) {
                error('Arc connected cluster not configured');
                info('Run "vi-arc cluster arc-connect" or "vi-arc k8s arc-connect" first');
                process.exit(1);
            }

            // Generate token
            const token = await withSpinner('Generating extension access token...', async () => {
                return await autoGenerateExtensionToken();
            });

            success('Extension access token generated successfully!');
            console.log();
            info('Token will auto-refresh when expired');
            info('You can now use API commands without manual authentication');
            
            // Show token expiry
            const expiry = config.get('viApiTokenExpiry');
            if (expiry) {
                const expiryDate = new Date(expiry);
                console.log(chalk.gray(`Token expires: ${expiryDate.toLocaleString()}`));
            }

        } catch (err) {
            error(`Authentication failed: ${err.message}`);
            console.log();
            info('Troubleshooting:');
            console.log(chalk.gray('  1. Make sure you are logged in: az login'));
            console.log(chalk.gray('  2. Verify VI account is configured: vi-arc config show'));
            console.log(chalk.gray('  3. Verify Arc connection is established: vi-arc status'));
            console.log(chalk.gray('  4. Try manual token: vi-arc api auth --manual'));
            process.exit(1);
        }
    });

// Show auth status
apiCommand
    .command('auth-status')
    .description('Show authentication status')
    .action(async () => {
        const cfg = config.getConfig();
        
        console.log(chalk.cyan.bold('Authentication Status'));
        console.log();

        const table = new Table({
            style: { head: [], border: [] },
            colWidths: [25, 50]
        });

        // Check Azure CLI
        let azCliStatus = chalk.red('Not logged in');
        try {
            await getAzureAccessToken();
            azCliStatus = chalk.green('Logged in');
        } catch {
            azCliStatus = chalk.red('Not logged in');
        }
        table.push([chalk.gray('Azure CLI'), azCliStatus]);

        // Check VI Account
        const viAccount = cfg.viAccountResourceId
            ? chalk.green('Configured')
            : chalk.yellow('Not configured');
        table.push([chalk.gray('VI Account'), viAccount]);

        // Check Arc Connection
        const arcConnection = (cfg.connectedClusterName && cfg.resourceGroup)
            ? chalk.green('Configured')
            : chalk.yellow('Not configured');
        table.push([chalk.gray('Arc Connection'), arcConnection]);

        // Check API Token
        let tokenStatus = chalk.red('No token');
        if (cfg.viApiToken) {
            const expiry = cfg.viApiTokenExpiry;
            if (expiry && Date.now() < expiry) {
                const expiryDate = new Date(expiry);
                tokenStatus = chalk.green(`Valid (expires ${expiryDate.toLocaleTimeString()})`);
            } else if (expiry) {
                tokenStatus = chalk.yellow('Expired (will auto-refresh)');
            } else {
                tokenStatus = chalk.green('Set (manual token)');
            }
        }
        table.push([chalk.gray('API Token'), tokenStatus]);

        console.log(table.toString());
        console.log();

        // Check if ready for API calls
        if (cfg.viApiToken && cfg.viAccountId && cfg.viEndpointUri) {
            success('Ready for API calls');
        } else {
            warn('Not ready for API calls');
            if (!cfg.viApiToken) {
                info('Run "vi-arc api auth" to authenticate');
            }
            if (!cfg.viAccountId) {
                info('Run "vi-arc setup" to configure VI account');
            }
        }
    });

// ============ Camera Commands ============

const cameraCmd = apiCommand
    .command('camera')
    .description('Camera management');

// List cameras
cameraCmd
    .command('list')
    .description('List all cameras')
    .option('--status <status>', 'Filter by status (0-3)')
    .option('--preset <presetId>', 'Filter by preset ID')
    .option('--limit <n>', 'Number of results', '25')
    .option('--json', 'Output as JSON')
    .action(async (options) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const cameras = await withSpinner('Fetching cameras...', async () => {
                return await client.listCameras({
                    pageSize: parseInt(options.limit),
                    status: options.status,
                    presetIds: options.preset
                });
            });

            if (options.json) {
                console.log(JSON.stringify(cameras, null, 2));
                return;
            }

            if (!cameras.results || cameras.results.length === 0) {
                info('No cameras found');
                return;
            }

            console.log(chalk.cyan.bold('Cameras'));
            console.log();

            const table = new Table({
                head: [
                    chalk.cyan('ID'),
                    chalk.cyan('Name'),
                    chalk.cyan('Status'),
                    chalk.cyan('Streaming'),
                    chalk.cyan('Recording')
                ],
                style: { head: [], border: [] }
            });

            for (const cam of cameras.results) {
                table.push([
                    cam.id.substring(0, 8) + '...',
                    cam.name,
                    getStatusText(cam.status),
                    cam.liveStreamingEnabled ? chalk.green('Yes') : chalk.gray('No'),
                    cam.recordingEnabled ? chalk.green('Yes') : chalk.gray('No')
                ]);
            }

            console.log(table.toString());
            console.log();
            info(`Total: ${cameras.results.length} camera(s)`);

        } catch (err) {
            error(`Failed to list cameras: ${err.message}`);
            process.exit(1);
        }
    });

// Add camera
cameraCmd
    .command('add')
    .description('Add a new camera')
    .option('--name <name>', 'Camera name')
    .option('--rtsp <url>', 'RTSP URL')
    .option('--preset <presetId>', 'Preset ID')
    .option('--description <desc>', 'Description')
    .option('--streaming', 'Enable live streaming', true)
    .option('--recording', 'Enable recording', true)
    .option('--retention <hours>', 'Recordings retention in hours', '720')
    .action(async (options) => {
        try {
            let name = options.name;
            let rtspUrl = options.rtsp;
            let presetId = options.preset;

            if (!name || !rtspUrl) {
                const answers = await prompt([
                    {
                        type: 'input',
                        name: 'name',
                        message: 'Camera name:',
                        initial: options.name,
                        validate: v => v?.length > 0 || 'Name is required'
                    },
                    {
                        type: 'input',
                        name: 'rtspUrl',
                        message: 'RTSP URL:',
                        initial: options.rtsp,
                        validate: v => v?.startsWith('rtsp://') || 'Must be a valid RTSP URL'
                    },
                    {
                        type: 'input',
                        name: 'presetId',
                        message: 'Preset ID (optional):',
                        initial: options.preset
                    },
                    {
                        type: 'input',
                        name: 'description',
                        message: 'Description (optional):',
                        initial: options.description
                    }
                ]);
                name = answers.name;
                rtspUrl = answers.rtspUrl;
                presetId = answers.presetId;
                options.description = answers.description;
            }

            const client = VideoIndexerClient.fromConfig();
            
            const camera = await withSpinner('Adding camera...', async () => {
                return await client.addCamera({
                    name,
                    rtspUrl,
                    presetId: presetId || undefined,
                    description: options.description,
                    liveStreamingEnabled: options.streaming,
                    recordingEnabled: options.recording,
                    recordingsRetentionInHours: parseInt(options.retention),
                    insightsRetentionInHours: parseInt(options.retention)
                });
            });

            success(`Camera added: ${camera.name}`);
            console.log(chalk.gray(`ID: ${camera.id}`));

        } catch (err) {
            error(`Failed to add camera: ${err.message}`);
            process.exit(1);
        }
    });

// Get camera details
cameraCmd
    .command('get <cameraId>')
    .description('Get camera details')
    .option('--json', 'Output as JSON')
    .action(async (cameraId, options) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const camera = await withSpinner('Fetching camera...', async () => {
                return await client.getCamera(cameraId);
            });

            if (options.json) {
                console.log(JSON.stringify(camera, null, 2));
                return;
            }

            console.log(boxen(
                chalk.cyan.bold(camera.name) + '\n\n' +
                chalk.gray('ID: ') + chalk.white(camera.id) + '\n' +
                chalk.gray('Status: ') + getStatusText(camera.status) + '\n' +
                chalk.gray('RTSP URL: ') + chalk.white(camera.rtspUrl || 'N/A') + '\n' +
                chalk.gray('Preset ID: ') + chalk.white(camera.presetId || 'None') + '\n' +
                chalk.gray('Streaming: ') + (camera.liveStreamingEnabled ? chalk.green('Enabled') : chalk.gray('Disabled')) + '\n' +
                chalk.gray('Recording: ') + (camera.recordingEnabled ? chalk.green('Enabled') : chalk.gray('Disabled')) + '\n' +
                chalk.gray('Description: ') + chalk.white(camera.description || 'None'),
                { padding: 1, borderStyle: 'round', borderColor: 'cyan' }
            ));

        } catch (err) {
            error(`Failed to get camera: ${err.message}`);
            process.exit(1);
        }
    });

// Delete camera
cameraCmd
    .command('delete <cameraId>')
    .description('Delete a camera')
    .option('--yes', 'Skip confirmation')
    .action(async (cameraId, options) => {
        try {
            if (!options.yes) {
                const { confirmed } = await prompt({
                    type: 'confirm',
                    name: 'confirmed',
                    message: `Delete camera ${cameraId}?`,
                    initial: false
                });
                if (!confirmed) {
                    info('Cancelled');
                    return;
                }
            }

            const client = VideoIndexerClient.fromConfig();
            
            await withSpinner('Deleting camera...', async () => {
                await client.deleteCamera(cameraId);
            });

            success('Camera deleted');

        } catch (err) {
            error(`Failed to delete camera: ${err.message}`);
            process.exit(1);
        }
    });

// ============ Preset Commands ============

const presetCmd = apiCommand
    .command('preset')
    .description('Preset management');

// List presets
presetCmd
    .command('list')
    .description('List all presets')
    .option('--limit <n>', 'Number of results', '25')
    .option('--json', 'Output as JSON')
    .action(async (options) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const presets = await withSpinner('Fetching presets...', async () => {
                return await client.listPresets({
                    pageSize: parseInt(options.limit)
                });
            });

            if (options.json) {
                console.log(JSON.stringify(presets, null, 2));
                return;
            }

            if (!presets.results || presets.results.length === 0) {
                info('No presets found');
                return;
            }

            console.log(chalk.cyan.bold('Presets'));
            console.log();

            const table = new Table({
                head: [
                    chalk.cyan('ID'),
                    chalk.cyan('Name'),
                    chalk.cyan('Description'),
                    chalk.cyan('Created')
                ],
                style: { head: [], border: [] }
            });

            for (const preset of presets.results) {
                table.push([
                    preset.id?.substring(0, 8) + '...' || 'N/A',
                    preset.name || 'N/A',
                    (preset.description || '').substring(0, 30) + ((preset.description?.length > 30) ? '...' : ''),
                    preset.createTime ? new Date(preset.createTime).toLocaleDateString() : 'N/A'
                ]);
            }

            console.log(table.toString());

        } catch (err) {
            error(`Failed to list presets: ${err.message}`);
            process.exit(1);
        }
    });

// Create preset
presetCmd
    .command('create')
    .description('Create a new preset')
    .option('--name <name>', 'Preset name')
    .option('--description <desc>', 'Preset description')
    .option('--json <config>', 'Preset configuration as JSON')
    .action(async (options) => {
        try {
            let name = options.name;
            
            if (!name) {
                const answers = await prompt([
                    {
                        type: 'input',
                        name: 'name',
                        message: 'Preset name:',
                        validate: v => v?.length > 0 || 'Name is required'
                    },
                    {
                        type: 'input',
                        name: 'description',
                        message: 'Description (optional):'
                    }
                ]);
                name = answers.name;
                options.description = answers.description;
            }

            const presetConfig = options.json ? JSON.parse(options.json) : {};
            
            const client = VideoIndexerClient.fromConfig();
            
            const preset = await withSpinner('Creating preset...', async () => {
                return await client.createPreset({
                    name,
                    description: options.description,
                    ...presetConfig
                });
            });

            success(`Preset created: ${preset.name}`);
            console.log(chalk.gray(`ID: ${preset.id}`));

        } catch (err) {
            error(`Failed to create preset: ${err.message}`);
            process.exit(1);
        }
    });

// ============ Custom Insights Commands ============

const insightCmd = apiCommand
    .command('insight')
    .description('Custom insights management');

// List custom insights
insightCmd
    .command('list')
    .description('List custom insights')
    .option('--limit <n>', 'Number of results', '25')
    .option('--json', 'Output as JSON')
    .action(async (options) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const insights = await withSpinner('Fetching custom insights...', async () => {
                return await client.listCustomInsights({
                    pageSize: parseInt(options.limit)
                });
            });

            if (options.json) {
                console.log(JSON.stringify(insights, null, 2));
                return;
            }

            if (!insights.results || insights.results.length === 0) {
                info('No custom insights found');
                return;
            }

            console.log(chalk.cyan.bold('Custom Insights'));
            console.log();

            const table = new Table({
                head: [
                    chalk.cyan('ID'),
                    chalk.cyan('Name'),
                    chalk.cyan('Model Type'),
                    chalk.cyan('Created')
                ],
                style: { head: [], border: [] }
            });

            for (const insight of insights.results) {
                table.push([
                    insight.id?.substring(0, 8) + '...' || 'N/A',
                    insight.insightName || 'N/A',
                    getModelTypeText(insight.modelType),
                    insight.createTime ? new Date(insight.createTime).toLocaleDateString() : 'N/A'
                ]);
            }

            console.log(table.toString());

        } catch (err) {
            error(`Failed to list insights: ${err.message}`);
            process.exit(1);
        }
    });

// Create custom insight
insightCmd
    .command('create')
    .description('Create a custom insight')
    .option('--name <name>', 'Insight name')
    .option('--description <desc>', 'Description')
    .option('--model-type <type>', 'Model type (1=ObjectDetection, 2=Classification)', '1')
    .option('--prompt <text>', 'Detection prompt')
    .action(async (options) => {
        try {
            let name = options.name;
            let promptText = options.prompt;
            
            if (!name || !promptText) {
                const answers = await prompt([
                    {
                        type: 'input',
                        name: 'name',
                        message: 'Insight name:',
                        initial: options.name,
                        validate: v => v?.length > 0 || 'Name is required'
                    },
                    {
                        type: 'input',
                        name: 'description',
                        message: 'Description (optional):',
                        initial: options.description
                    },
                    {
                        type: 'select',
                        name: 'modelType',
                        message: 'Model type:',
                        choices: [
                            { name: 'Object Detection', value: '1' },
                            { name: 'Classification', value: '2' }
                        ],
                        initial: 0
                    },
                    {
                        type: 'input',
                        name: 'prompt',
                        message: 'Detection prompt:',
                        initial: options.prompt,
                        validate: v => v?.length > 0 || 'Prompt is required'
                    }
                ]);
                name = answers.name;
                promptText = answers.prompt;
                options.description = answers.description;
                options.modelType = answers.modelType;
            }

            const client = VideoIndexerClient.fromConfig();
            
            const insight = await withSpinner('Creating custom insight...', async () => {
                return await client.createCustomInsight({
                    insightName: name,
                    description: options.description,
                    modelType: parseInt(options.modelType),
                    prompt: {
                        text: promptText,
                        images: []
                    }
                });
            });

            success(`Custom insight created: ${insight.insightName}`);
            console.log(chalk.gray(`ID: ${insight.id}`));

        } catch (err) {
            error(`Failed to create insight: ${err.message}`);
            process.exit(1);
        }
    });

// ============ Video Commands ============

const videoCmd = apiCommand
    .command('video')
    .description('Video management');

// List videos
videoCmd
    .command('list')
    .description('List videos')
    .option('--source <cameraId>', 'Filter by camera ID or "Upload"')
    .option('--limit <n>', 'Number of results', '25')
    .option('--json', 'Output as JSON')
    .action(async (options) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const videos = await withSpinner('Fetching videos...', async () => {
                return await client.listVideos({
                    pageSize: parseInt(options.limit),
                    source: options.source
                });
            });

            if (options.json) {
                console.log(JSON.stringify(videos, null, 2));
                return;
            }

            if (!videos.results || videos.results.length === 0) {
                info('No videos found');
                return;
            }

            console.log(chalk.cyan.bold('Videos'));
            console.log();

            const table = new Table({
                head: [
                    chalk.cyan('ID'),
                    chalk.cyan('Name'),
                    chalk.cyan('Duration'),
                    chalk.cyan('State'),
                    chalk.cyan('Created')
                ],
                style: { head: [], border: [] }
            });

            for (const video of videos.results) {
                table.push([
                    video.id?.substring(0, 12) || 'N/A',
                    (video.name || 'N/A').substring(0, 25),
                    formatDuration(video.durationInSeconds),
                    getVideoStateText(video.state),
                    video.created ? new Date(video.created).toLocaleDateString() : 'N/A'
                ]);
            }

            console.log(table.toString());
            console.log();
            info(`Total: ${videos.results.length} video(s)`);

        } catch (err) {
            error(`Failed to list videos: ${err.message}`);
            process.exit(1);
        }
    });

// Search videos
videoCmd
    .command('search <query>')
    .description('Search videos with natural language')
    .option('--source <cameraId>', 'Filter by camera ID')
    .option('--limit <n>', 'Number of results', '10')
    .option('--json', 'Output as JSON')
    .action(async (query, options) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const results = await withSpinner('Searching...', async () => {
                const filters = {};
                if (options.source) {
                    filters.source = [options.source];
                }
                
                return await client.searchVideos({
                    query,
                    filters,
                    pageSize: parseInt(options.limit)
                });
            });

            if (options.json) {
                console.log(JSON.stringify(results, null, 2));
                return;
            }

            if (!results.results || results.results.length === 0) {
                info('No results found');
                return;
            }

            console.log(chalk.cyan.bold(`Search Results for: "${query}"`));
            console.log();

            for (const result of results.results) {
                console.log(chalk.white.bold(`Video: ${result.videoId}`));
                console.log(chalk.gray(`  Time: ${formatDuration(result.start)} - ${formatDuration(result.end)}`));
                console.log(chalk.gray(`  Confidence: ${(result.confidence * 100).toFixed(1)}%`));
                if (result.detectedAis?.length > 0) {
                    console.log(chalk.gray(`  Detected: ${result.detectedAis.map(a => a.insightName).join(', ')}`));
                }
                console.log();
            }

        } catch (err) {
            error(`Search failed: ${err.message}`);
            process.exit(1);
        }
    });

// ============ Tags Commands ============

const tagCmd = apiCommand
    .command('tag')
    .description('Tag management');

tagCmd
    .command('list')
    .description('List tags')
    .option('--key <key>', 'Filter by key')
    .option('--json', 'Output as JSON')
    .action(async (options) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const tags = await withSpinner('Fetching tags...', async () => {
                return await client.listTags({ key: options.key });
            });

            if (options.json) {
                console.log(JSON.stringify(tags, null, 2));
                return;
            }

            if (!tags.results || tags.results.length === 0) {
                info('No tags found');
                return;
            }

            console.log(chalk.cyan.bold('Tags'));
            console.log();

            const table = new Table({
                head: [chalk.cyan('ID'), chalk.cyan('Key'), chalk.cyan('Value')],
                style: { head: [], border: [] }
            });

            for (const tag of tags.results) {
                table.push([
                    tag.id?.substring(0, 8) + '...',
                    tag.key,
                    tag.value
                ]);
            }

            console.log(table.toString());

        } catch (err) {
            error(`Failed to list tags: ${err.message}`);
            process.exit(1);
        }
    });

tagCmd
    .command('create <key> <value>')
    .description('Create a tag')
    .action(async (key, value) => {
        try {
            const client = VideoIndexerClient.fromConfig();
            
            const tag = await withSpinner('Creating tag...', async () => {
                return await client.createTag({ key, value });
            });

            success(`Tag created: ${tag.key}=${tag.value}`);

        } catch (err) {
            error(`Failed to create tag: ${err.message}`);
            process.exit(1);
        }
    });

// Helper functions
function getStatusText(status) {
    const statuses = {
        0: chalk.gray('Inactive'),
        1: chalk.green('Active'),
        2: chalk.yellow('Starting'),
        3: chalk.red('Error')
    };
    return statuses[status] || chalk.gray('Unknown');
}

function getModelTypeText(type) {
    const types = {
        1: 'Object Detection',
        2: 'Classification'
    };
    return types[type] || 'Unknown';
}

function getVideoStateText(state) {
    const states = {
        0: chalk.gray('Queued'),
        1: chalk.yellow('Processing'),
        2: chalk.green('Processed'),
        3: chalk.red('Failed')
    };
    return states[state] || chalk.gray('Unknown');
}

function formatDuration(seconds) {
    if (!seconds) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}
