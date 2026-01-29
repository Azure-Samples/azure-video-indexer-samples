/**
 * Configuration management for VI Arc CLI
 */

import Conf from 'conf';
import { generateRandomSuffix } from './exec.js';

const config = new Conf({
    projectName: 'vi-arc-cli',
    schema: {
        subscriptionId: { type: 'string' },
        region: { type: 'string' },
        resourcesPrefix: { type: 'string' },
        randomSuffix: { type: 'string' },
        
        // Derived names
        resourceGroup: { type: 'string' },
        aksClusterName: { type: 'string' },
        connectedClusterName: { type: 'string' },
        nodePoolResourceGroup: { type: 'string' },
        kubectlContext: { type: 'string' },
        dnsLabel: { type: 'string' },
        
        // VM Sizes
        nodeVmSize: { type: 'string', default: 'Standard_D4a_v4' },
        workerVmSize: { type: 'string', default: 'Standard_D32a_v4' },
        summarizationCpuVm: { type: 'string', default: 'Standard_F32s_v2' },
        gpuVmSize: { type: 'string', default: 'Standard_NC40ads_H100_v5' },
        
        // Feature flags
        enableSummarizationGpu: { type: 'boolean', default: false },
        enableSummarizationCpu: { type: 'boolean', default: false },
        
        // Video Indexer Extension
        viExtensionName: { type: 'string', default: 'video-indexer' },
        viExtensionVersion: { type: 'string' },
        viReleaseTrain: { type: 'string', default: 'preview' },
        viAccountId: { type: 'string' },
        viAccountResourceId: { type: 'string' },
        viEndpointUri: { type: 'string' },
        viLiveVideoEnabled: { type: 'boolean', default: true },
        viMediaUploadsEnabled: { type: 'boolean', default: true },
        viLiveSummarizationEnabled: { type: 'boolean', default: false },
        viGpuSummarization: { type: 'boolean', default: false },
        viDeepstreamNodeSelector: { type: 'string', default: 'deepstream' },
        viSummarizationNodeSelector: { type: 'string', default: 'summarization' },
        viGpuTolerationsKey: { type: 'string', default: 'nvidia.com/gpu' },
        
        // SSL Configuration
        keyVaultName: { type: 'string' },
        sslCertUri: { type: 'string' },
        
        // State tracking
        setupCompleted: {
            type: 'object',
            default: {
                prerequisites: false,
                resourceGroup: false,
                aksCluster: false,
                nodePools: false,
                gpuOperator: false,
                ingress: false,
                arcConnection: false,
                certManager: false,
                viExtension: false
            }
        }
    }
});

/**
 * Get all configuration values
 * @returns {Object}
 */
export function getConfig() {
    return config.store;
}

/**
 * Get a specific configuration value
 * @param {string} key - Configuration key
 * @returns {any}
 */
export function get(key) {
    return config.get(key);
}

/**
 * Set a configuration value
 * @param {string} key - Configuration key
 * @param {any} value - Configuration value
 */
export function set(key, value) {
    config.set(key, value);
}

/**
 * Set multiple configuration values
 * @param {Object} values - Key-value pairs to set
 */
export function setMultiple(values) {
    for (const [key, value] of Object.entries(values)) {
        config.set(key, value);
    }
}

/**
 * Clear all configuration
 */
export function clearConfig() {
    config.clear();
}

/**
 * Initialize configuration with prefix
 * @param {string} prefix - Resource naming prefix
 * @param {string} region - Azure region
 * @param {string} subscriptionId - Azure subscription ID
 */
export function initializeConfig(prefix, region, subscriptionId) {
    const randomSuffix = generateRandomSuffix();
    
    config.set('subscriptionId', subscriptionId);
    config.set('region', region);
    config.set('resourcesPrefix', prefix);
    config.set('randomSuffix', randomSuffix);
    
    // Derived names
    config.set('resourceGroup', `${prefix}-rg`);
    config.set('aksClusterName', `${prefix}-aks`);
    config.set('connectedClusterName', `${prefix}-connected-aks`);
    config.set('nodePoolResourceGroup', `${prefix}-aks-agentpool-rg`);
    config.set('kubectlContext', prefix);
    config.set('dnsLabel', `${prefix}${randomSuffix}`);
    
    // Endpoint URI
    config.set('viEndpointUri', `https://${prefix}${randomSuffix}.${region}.cloudapp.azure.com`);
}

/**
 * Update setup completion status
 * @param {string} step - Step name
 * @param {boolean} completed - Completion status
 */
export function updateSetupStatus(step, completed) {
    const status = config.get('setupCompleted') || {};
    status[step] = completed;
    config.set('setupCompleted', status);
}

/**
 * Get setup completion status
 * @returns {Object}
 */
export function getSetupStatus() {
    return config.get('setupCompleted') || {};
}

/**
 * Check if a step is completed
 * @param {string} step - Step name
 * @returns {boolean}
 */
export function isStepCompleted(step) {
    const status = config.get('setupCompleted') || {};
    return status[step] === true;
}

/**
 * Get configuration file path
 * @returns {string}
 */
export function getConfigPath() {
    return config.path;
}

/**
 * Export configuration to JSON string
 * @returns {string}
 */
export function exportConfig() {
    return JSON.stringify(config.store, null, 2);
}

/**
 * Import configuration from JSON string
 * @param {string} jsonString - JSON configuration string
 */
export function importConfig(jsonString) {
    const imported = JSON.parse(jsonString);
    for (const [key, value] of Object.entries(imported)) {
        config.set(key, value);
    }
}

/**
 * Get default VM sizes
 * @returns {Object}
 */
export function getDefaultVmSizes() {
    return {
        system: 'Standard_D4a_v4',
        worker: 'Standard_D32a_v4',
        summarizationCpu: 'Standard_F32s_v2',
        gpu: 'Standard_NC40ads_H100_v5',
        gpuA100: 'Standard_NC24ads_A100_v4',
        gpuA10: 'Standard_NV36ads_A10_v5'
    };
}

/**
 * Get GPU VM options
 * @returns {Array<{name: string, value: string, description: string}>}
 */
export function getGpuVmOptions() {
    return [
        {
            name: 'H100 (Standard_NC40ads_H100_v5)',
            value: 'Standard_NC40ads_H100_v5',
            description: 'Best performance - 40 vCPUs, 320 GB RAM, 1 H100 GPU'
        },
        {
            name: 'A100 (Standard_NC24ads_A100_v4)',
            value: 'Standard_NC24ads_A100_v4',
            description: 'High performance - 24 vCPUs, 220 GB RAM, 1 A100 GPU'
        },
        {
            name: 'A10 (Standard_NV36ads_A10_v5)',
            value: 'Standard_NV36ads_A10_v5',
            description: 'Cost-effective - 36 vCPUs, 440 GB RAM, 1 A10 GPU'
        }
    ];
}

export default config;
