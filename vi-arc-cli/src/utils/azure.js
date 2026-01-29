/**
 * Azure CLI helper functions for auto-detection
 */

import { az, commandExists, withSpinner } from './exec.js';
import * as config from './config.js';
import chalk from 'chalk';

/**
 * Check if Azure CLI is installed and logged in
 * @returns {Promise<boolean>}
 */
export async function checkAzureCli() {
    const exists = await commandExists('az');
    if (!exists) {
        return { installed: false, loggedIn: false };
    }
    
    try {
        await az(['account', 'show'], { silent: true });
        return { installed: true, loggedIn: true };
    } catch {
        return { installed: true, loggedIn: false };
    }
}

/**
 * Get current Azure subscription
 * @returns {Promise<{id: string, name: string, tenantId: string}>}
 */
export async function getCurrentSubscription() {
    const account = await az(['account', 'show']);
    return {
        id: account.id,
        name: account.name,
        tenantId: account.tenantId
    };
}

/**
 * List all Azure subscriptions
 * @returns {Promise<Array<{id: string, name: string, isDefault: boolean}>>}
 */
export async function listSubscriptions() {
    const subscriptions = await az(['account', 'list']);
    return subscriptions.map(sub => ({
        id: sub.id,
        name: sub.name,
        isDefault: sub.isDefault
    }));
}

/**
 * Set Azure subscription
 * @param {string} subscriptionId - Subscription ID
 */
export async function setSubscription(subscriptionId) {
    await az(['account', 'set', '--subscription', subscriptionId], { json: false });
}

/**
 * Get available regions for a specific VM size
 * @param {string} vmSize - VM size to check
 * @returns {Promise<string[]>}
 */
export async function getRegionsForVmSize(vmSize) {
    try {
        const skus = await az(['vm', 'list-skus', '--size', vmSize, '--all']);
        const regions = [...new Set(skus
            .filter(sku => !sku.restrictions || sku.restrictions.length === 0)
            .map(sku => sku.locations)
            .flat())];
        return regions;
    } catch {
        return [];
    }
}

/**
 * Check GPU quota for a region
 * @param {string} region - Azure region
 * @param {string} gpuType - GPU type (H100, A100, A10)
 * @returns {Promise<{available: boolean, currentUsage: number, limit: number, name: string}>}
 */
export async function checkGpuQuota(region, gpuType) {
    const quotaPatterns = {
        'H100': 'NCadsH100v5',
        'A100': 'NCADS_A100_v4',
        'A10': 'NVadsA10'
    };
    
    const pattern = quotaPatterns[gpuType] || gpuType;
    
    try {
        const usage = await az(['vm', 'list-usage', '--location', region]);
        const gpuQuota = usage.find(u => 
            u.name.localizedValue.toLowerCase().includes(pattern.toLowerCase()) ||
            u.name.value.toLowerCase().includes(pattern.toLowerCase())
        );
        
        if (gpuQuota) {
            return {
                available: gpuQuota.limit > gpuQuota.currentValue,
                currentUsage: gpuQuota.currentValue,
                limit: gpuQuota.limit,
                name: gpuQuota.name.localizedValue
            };
        }
        
        return { available: false, currentUsage: 0, limit: 0, name: `${gpuType} quota` };
    } catch {
        return { available: false, currentUsage: 0, limit: 0, name: `${gpuType} quota` };
    }
}

/**
 * List Video Indexer accounts in the subscription
 * @returns {Promise<Array<{name: string, resourceGroup: string, accountId: string, location: string, resourceId: string}>>}
 */
export async function listVideoIndexerAccounts() {
    try {
        const subscriptionId = (await getCurrentSubscription()).id;
        const response = await az([
            'rest', '--method', 'get',
            '--uri', `https://management.azure.com/subscriptions/${subscriptionId}/providers/Microsoft.VideoIndexer/accounts?api-version=2024-01-01`
        ]);
        
        if (response.value) {
            return response.value.map(account => ({
                name: account.name,
                resourceGroup: account.id.split('/')[4],
                accountId: account.properties.accountId,
                location: account.location,
                resourceId: account.id
            }));
        }
        return [];
    } catch {
        return [];
    }
}

/**
 * Get Video Indexer account details
 * @param {string} resourceGroup - Resource group name
 * @param {string} accountName - Account name
 * @returns {Promise<{accountId: string, accountName: string, resourceId: string, location: string}>}
 */
export async function getVideoIndexerAccount(resourceGroup, accountName) {
    const subscriptionId = (await getCurrentSubscription()).id;
    const response = await az([
        'rest', '--method', 'get',
        '--uri', `https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}?api-version=2024-01-01`
    ]);
    
    return {
        accountId: response.properties.accountId,
        accountName: response.name,
        resourceId: response.id,
        location: response.location
    };
}

/**
 * Get the latest AKS version for a region
 * @param {string} region - Azure region
 * @returns {Promise<string>}
 */
export async function getLatestAksVersion(region) {
    const versions = await az(['aks', 'get-versions', '--location', region, '--query', 'values[].patchVersions.keys(@)[][] | sort(@) | [-1]']);
    return versions;
}

/**
 * Check if a resource group exists
 * @param {string} name - Resource group name
 * @returns {Promise<boolean>}
 */
export async function resourceGroupExists(name) {
    try {
        await az(['group', 'show', '--name', name]);
        return true;
    } catch {
        return false;
    }
}

/**
 * Check if an AKS cluster exists
 * @param {string} name - Cluster name
 * @param {string} resourceGroup - Resource group name
 * @returns {Promise<boolean>}
 */
export async function aksClusterExists(name, resourceGroup) {
    try {
        await az(['aks', 'show', '--name', name, '--resource-group', resourceGroup]);
        return true;
    } catch {
        return false;
    }
}

/**
 * Check if Arc connected cluster exists
 * @param {string} name - Cluster name
 * @param {string} resourceGroup - Resource group name
 * @returns {Promise<boolean>}
 */
export async function arcClusterExists(name, resourceGroup) {
    try {
        await az(['connectedk8s', 'show', '--name', name, '--resource-group', resourceGroup]);
        return true;
    } catch {
        return false;
    }
}

/**
 * Get AKS cluster node pools
 * @param {string} clusterName - Cluster name
 * @param {string} resourceGroup - Resource group name
 * @returns {Promise<Array>}
 */
export async function getNodePools(clusterName, resourceGroup) {
    try {
        const pools = await az(['aks', 'nodepool', 'list', '--cluster-name', clusterName, '--resource-group', resourceGroup]);
        return pools;
    } catch {
        return [];
    }
}

/**
 * List available Azure regions
 * @returns {Promise<Array<{name: string, displayName: string}>>}
 */
export async function listRegions() {
    const locations = await az(['account', 'list-locations']);
    return locations
        .filter(loc => loc.metadata.regionType === 'Physical')
        .map(loc => ({
            name: loc.name,
            displayName: loc.displayName
        }))
        .sort((a, b) => a.displayName.localeCompare(b.displayName));
}

/**
 * Get list of common regions that support GPU workloads
 * @returns {string[]}
 */
export function getGpuRegions() {
    return [
        'eastus',
        'eastus2',
        'westus2',
        'westus3',
        'centralus',
        'northcentralus',
        'southcentralus',
        'westeurope',
        'northeurope',
        'uksouth',
        'southeastasia',
        'eastasia',
        'australiaeast',
        'japaneast'
    ];
}

// ============ Token Management ============

/**
 * Get Azure Management API access token using az cli
 * @returns {Promise<string>}
 */
export async function getAzureAccessToken() {
    const result = await az([
        'account', 'get-access-token',
        '--resource', 'https://management.azure.com/',
        '--query', 'accessToken',
        '-o', 'tsv'
    ], { json: false });
    
    return result.trim();
}

/**
 * Get the extension resource ID from the connected cluster
 * @param {string} connectedClusterName - Arc connected cluster name
 * @param {string} resourceGroup - Resource group name
 * @param {string} extensionName - Extension name (default: video-indexer)
 * @returns {Promise<string>}
 */
export async function getExtensionResourceId(connectedClusterName, resourceGroup, extensionName = 'video-indexer') {
    const subscriptionId = (await getCurrentSubscription()).id;
    
    // The extension ID format:
    // /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Kubernetes/connectedClusters/{cluster}/Providers/Microsoft.KubernetesConfiguration/extensions/{ext}
    return `/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Kubernetes/connectedClusters/${connectedClusterName}/Providers/Microsoft.KubernetesConfiguration/extensions/${extensionName}`;
}

/**
 * Generate Video Indexer Extension Access Token
 * This token is used to call the Video Indexer Arc APIs
 *
 * @param {Object} options - Token generation options
 * @param {string} options.subscriptionId - Azure subscription ID
 * @param {string} options.resourceGroup - VI account resource group
 * @param {string} options.accountName - VI account name
 * @param {string} options.extensionId - Full extension resource ID
 * @param {string} options.permissionType - Permission type (Contributor, Reader)
 * @param {string} options.scope - Token scope (Account)
 * @returns {Promise<{accessToken: string, expiresIn: number}>}
 */
export async function generateExtensionAccessToken(options) {
    const {
        subscriptionId,
        resourceGroup,
        accountName,
        extensionId,
        permissionType = 'Contributor',
        scope = 'Account'
    } = options;

    // First get Azure access token
    const azToken = await getAzureAccessToken();
    
    // Build the request body
    const requestBody = {
        permissionType,
        scope,
        extensionId
    };
    
    // Call the generateExtensionAccessToken API
    const uri = `https://management.azure.com/subscriptions/${subscriptionId}/resourcegroups/${resourceGroup}/providers/Microsoft.VideoIndexer/accounts/${accountName}/generateExtensionAccessToken?api-version=2025-03-01`;
    
    const response = await fetch(uri, {
        method: 'POST',
        headers: {
            'accept': 'application/json',
            'Authorization': `Bearer ${azToken}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
        const errorBody = await response.text();
        let errorMessage = `Failed to generate extension access token: ${response.status} ${response.statusText}`;
        try {
            const errorJson = JSON.parse(errorBody);
            errorMessage = errorJson.error?.message || errorJson.message || errorMessage;
        } catch {
            // Use default error message
        }
        throw new Error(errorMessage);
    }

    const result = await response.json();
    return {
        accessToken: result.accessToken,
        expiresIn: result.expiresIn || 3600
    };
}

/**
 * Auto-generate extension access token from config
 * Uses stored configuration to generate the token automatically
 * @returns {Promise<string>}
 */
export async function autoGenerateExtensionToken() {
    const cfg = config.getConfig();
    
    if (!cfg.viAccountResourceId) {
        throw new Error('Video Indexer account resource ID not configured. Run "vi-arc setup" first.');
    }
    
    // Parse the resource ID to extract components
    // Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.VideoIndexer/accounts/{name}
    const parts = cfg.viAccountResourceId.split('/');
    const subscriptionId = parts[2];
    const resourceGroup = parts[4];
    const accountName = parts[8];
    
    // Get the extension ID
    const extensionId = await getExtensionResourceId(
        cfg.connectedClusterName,
        cfg.resourceGroup, // This is the cluster's resource group
        cfg.viExtensionName || 'video-indexer'
    );
    
    const result = await generateExtensionAccessToken({
        subscriptionId,
        resourceGroup, // VI account's resource group
        accountName,
        extensionId,
        permissionType: 'Contributor',
        scope: 'Account'
    });
    
    // Save token and expiry to config
    config.set('viApiToken', result.accessToken);
    config.set('viApiTokenExpiry', Date.now() + (result.expiresIn * 1000) - 60000); // Expire 1 min early
    
    return result.accessToken;
}

/**
 * Get a valid extension access token, auto-refreshing if expired
 * @returns {Promise<string>}
 */
export async function getValidExtensionToken() {
    const cfg = config.getConfig();
    
    // Check if we have a valid cached token
    const token = cfg.viApiToken;
    const expiry = cfg.viApiTokenExpiry;
    
    if (token && expiry && Date.now() < expiry) {
        return token;
    }
    
    // Token is missing or expired, generate a new one
    return await autoGenerateExtensionToken();
}
