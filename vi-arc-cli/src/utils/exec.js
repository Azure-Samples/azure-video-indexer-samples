/**
 * Utility functions for executing Azure CLI commands
 */

import { spawn } from 'child_process';
import chalk from 'chalk';
import ora from 'ora';

/**
 * Execute a shell command and return the result
 * @param {string} command - Command to execute
 * @param {string[]} args - Command arguments
 * @param {Object} options - Options
 * @returns {Promise<{stdout: string, stderr: string, code: number}>}
 */
export async function exec(command, args = [], options = {}) {
    const { silent = false, cwd = process.cwd() } = options;
    
    return new Promise((resolve, reject) => {
        const proc = spawn(command, args, {
            cwd,
            shell: true,
            stdio: silent ? 'pipe' : ['inherit', 'pipe', 'pipe']
        });

        let stdout = '';
        let stderr = '';

        if (proc.stdout) {
            proc.stdout.on('data', (data) => {
                stdout += data.toString();
            });
        }

        if (proc.stderr) {
            proc.stderr.on('data', (data) => {
                stderr += data.toString();
            });
        }

        proc.on('close', (code) => {
            resolve({ stdout: stdout.trim(), stderr: stderr.trim(), code });
        });

        proc.on('error', (err) => {
            reject(err);
        });
    });
}

/**
 * Execute an Azure CLI command
 * @param {string[]} args - Azure CLI arguments
 * @param {Object} options - Options
 * @returns {Promise<any>}
 */
export async function az(args, options = {}) {
    const { silent = true, json = true } = options;
    
    const fullArgs = json ? [...args, '-o', 'json'] : args;
    const result = await exec('az', fullArgs, { silent, ...options });
    
    if (result.code !== 0) {
        throw new Error(result.stderr || `Azure CLI command failed with code ${result.code}`);
    }
    
    if (json && result.stdout) {
        try {
            return JSON.parse(result.stdout);
        } catch {
            return result.stdout;
        }
    }
    
    return result.stdout;
}

/**
 * Execute kubectl command
 * @param {string[]} args - kubectl arguments
 * @param {Object} options - Options
 * @returns {Promise<string>}
 */
export async function kubectl(args, options = {}) {
    const { silent = true } = options;
    const result = await exec('kubectl', args, { silent, ...options });
    
    if (result.code !== 0) {
        throw new Error(result.stderr || `kubectl command failed with code ${result.code}`);
    }
    
    return result.stdout;
}

/**
 * Execute helm command
 * @param {string[]} args - helm arguments
 * @param {Object} options - Options
 * @returns {Promise<string>}
 */
export async function helm(args, options = {}) {
    const { silent = true } = options;
    const result = await exec('helm', args, { silent, ...options });
    
    if (result.code !== 0) {
        throw new Error(result.stderr || `helm command failed with code ${result.code}`);
    }
    
    return result.stdout;
}

/**
 * Check if a command exists
 * @param {string} command - Command name
 * @returns {Promise<boolean>}
 */
export async function commandExists(command) {
    try {
        const checkCmd = process.platform === 'win32' ? 'where' : 'which';
        const result = await exec(checkCmd, [command], { silent: true });
        return result.code === 0;
    } catch {
        return false;
    }
}

/**
 * Run a task with a spinner
 * @param {string} text - Spinner text
 * @param {Function} task - Async task to run
 * @returns {Promise<any>}
 */
export async function withSpinner(text, task) {
    const spinner = ora({
        text,
        spinner: 'dots12',
        color: 'cyan'
    }).start();

    try {
        const result = await task(spinner);
        spinner.succeed();
        return result;
    } catch (error) {
        spinner.fail();
        throw error;
    }
}

/**
 * Format duration in human readable format
 * @param {number} ms - Duration in milliseconds
 * @returns {string}
 */
export function formatDuration(ms) {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    
    if (hours > 0) {
        return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
    }
    if (minutes > 0) {
        return `${minutes}m ${seconds % 60}s`;
    }
    return `${seconds}s`;
}

/**
 * Print a success message
 * @param {string} message - Message to print
 */
export function success(message) {
    console.log(chalk.green('✓'), chalk.green(message));
}

/**
 * Print an error message
 * @param {string} message - Message to print
 */
export function error(message) {
    console.log(chalk.red('✗'), chalk.red(message));
}

/**
 * Print a warning message
 * @param {string} message - Message to print
 */
export function warn(message) {
    console.log(chalk.yellow('⚠'), chalk.yellow(message));
}

/**
 * Print an info message
 * @param {string} message - Message to print
 */
export function info(message) {
    console.log(chalk.blue('ℹ'), chalk.blue(message));
}

/**
 * Print a step header
 * @param {number} step - Step number
 * @param {string} title - Step title
 */
export function stepHeader(step, title) {
    console.log();
    console.log(chalk.cyan.bold(`━━━ Step ${step}: ${title} ━━━`));
    console.log();
}

/**
 * Generate a random suffix for resource names
 * @returns {string}
 */
export function generateRandomSuffix() {
    return Math.floor(Math.random() * 900 + 100).toString();
}
