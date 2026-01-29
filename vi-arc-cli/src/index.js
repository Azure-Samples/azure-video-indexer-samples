#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import gradient from 'gradient-string';
import boxen from 'boxen';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';

// Import commands
import { setupCommand } from './commands/setup.js';
import { clusterCommand } from './commands/cluster.js';
import { extensionCommand } from './commands/extension.js';
import { cleanupCommand } from './commands/cleanup.js';
import { configCommand } from './commands/config.js';
import { statusCommand } from './commands/status.js';
import { apiCommand } from './commands/api.js';
import { k8sCommand } from './commands/k8s.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Read package.json for version
const pkg = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf-8'));

// ASCII art banner
const banner = `
██╗   ██╗██╗      █████╗ ██████╗  ██████╗
██║   ██║██║     ██╔══██╗██╔══██╗██╔════╝
██║   ██║██║     ███████║██████╔╝██║     
╚██╗ ██╔╝██║     ██╔══██║██╔══██╗██║     
 ╚████╔╝ ██║     ██║  ██║██║  ██║╚██████╗
  ╚═══╝  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
`;

const showBanner = () => {
    console.log(gradient.pastel.multiline(banner));
    console.log(boxen(
        chalk.white.bold('Video Indexer Arc CLI') + '\n' +
        chalk.gray(`Version ${pkg.version}`) + '\n' +
        chalk.cyan('Deploy Video Indexer on Azure Kubernetes Service'),
        {
            padding: 1,
            margin: { top: 0, bottom: 1 },
            borderStyle: 'round',
            borderColor: 'cyan'
        }
    ));
};

const program = new Command();

program
    .name('vi-arc')
    .description('CLI tool for deploying Video Indexer Arc on Azure Kubernetes Service')
    .version(pkg.version, '-v, --version', 'Display version number')
    .hook('preAction', (thisCommand) => {
        // Show banner only for main commands, not help
        if (thisCommand.args.length > 0 || process.argv.length > 2) {
            const cmd = process.argv[2];
            if (cmd && !['--help', '-h', '--version', '-v', 'help'].includes(cmd)) {
                showBanner();
            }
        }
    });

// Add commands
program.addCommand(setupCommand);
program.addCommand(clusterCommand);
program.addCommand(k8sCommand);
program.addCommand(extensionCommand);
program.addCommand(apiCommand);
program.addCommand(cleanupCommand);
program.addCommand(configCommand);
program.addCommand(statusCommand);

// Default action - show banner and help
program.action(() => {
    showBanner();
    program.help();
});

// Parse arguments
program.parse();
