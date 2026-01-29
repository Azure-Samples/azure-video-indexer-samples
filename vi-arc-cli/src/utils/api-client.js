/**
 * Video Indexer Arc API client
 */

import chalk from 'chalk';
import * as config from './config.js';
import { getValidExtensionToken, autoGenerateExtensionToken } from './azure.js';
import { error, warn } from './exec.js';

/**
 * API client for Video Indexer Arc
 */
export class VideoIndexerClient {
    constructor(endpointUri, accountId, token = null) {
        this.baseUrl = endpointUri?.replace(/\/$/, '');
        this.accountId = accountId;
        this.token = token;
        this.autoAuth = true; // Enable auto-authentication by default
    }

    /**
     * Initialize client from config with auto-authentication
     * @param {boolean} autoAuth - Whether to auto-generate tokens (default: true)
     * @returns {Promise<VideoIndexerClient>}
     */
    static async fromConfig(autoAuth = true) {
        const cfg = config.getConfig();
        
        if (!cfg.viEndpointUri) {
            throw new Error('Endpoint URI not configured. Run "vi-arc setup" first.');
        }
        
        if (!cfg.viAccountId) {
            throw new Error('Account ID not configured. Run "vi-arc setup" first.');
        }
        
        const client = new VideoIndexerClient(cfg.viEndpointUri, cfg.viAccountId, cfg.viApiToken);
        client.autoAuth = autoAuth;
        
        return client;
    }

    /**
     * Set authentication token manually
     * @param {string} token - JWT token
     */
    setToken(token) {
        this.token = token;
        config.set('viApiToken', token);
    }

    /**
     * Ensure we have a valid token (auto-refresh if needed)
     * @returns {Promise<string>}
     */
    async ensureToken() {
        if (this.autoAuth) {
            try {
                this.token = await getValidExtensionToken();
            } catch (err) {
                // If auto-auth fails, check if we have a manual token
                if (!this.token) {
                    throw new Error(`Auto-authentication failed: ${err.message}. Use "vi-arc api auth" to set a token manually.`);
                }
            }
        }
        
        if (!this.token) {
            throw new Error('No API token available. Use "vi-arc api auth" to authenticate or ensure auto-auth is configured.');
        }
        
        return this.token;
    }

    /**
     * Make an API request
     * @param {string} method - HTTP method
     * @param {string} path - API path
     * @param {Object} options - Request options
     * @returns {Promise<any>}
     */
    async request(method, path, options = {}) {
        const { body, query, headers: extraHeaders = {} } = options;
        
        // Ensure we have a valid token (auto-refresh if needed)
        await this.ensureToken();

        let url = `${this.baseUrl}/Accounts/${this.accountId}${path}`;
        
        if (query && Object.keys(query).length > 0) {
            const params = new URLSearchParams();
            for (const [key, value] of Object.entries(query)) {
                if (value !== undefined && value !== null) {
                    if (Array.isArray(value)) {
                        value.forEach(v => params.append(key, v));
                    } else {
                        params.append(key, value);
                    }
                }
            }
            url += `?${params.toString()}`;
        }

        const headers = {
            'Authorization': `Bearer ${this.token}`,
            'Content-Type': 'application/json',
            ...extraHeaders
        };

        const fetchOptions = {
            method,
            headers
        };

        if (body) {
            fetchOptions.body = JSON.stringify(body);
        }

        const response = await fetch(url, fetchOptions);
        
        if (!response.ok) {
            const errorBody = await response.text();
            let errorMessage = `API Error ${response.status}: ${response.statusText}`;
            try {
                const errorJson = JSON.parse(errorBody);
                errorMessage = errorJson.message || errorJson.error || errorMessage;
            } catch {
                // Use default error message
            }
            throw new Error(errorMessage);
        }

        // Handle 204 No Content
        if (response.status === 204) {
            return null;
        }

        // Handle 202 Accepted
        if (response.status === 202) {
            const location = response.headers.get('Location');
            const result = await response.json().catch(() => null);
            return { ...result, _location: location };
        }

        return response.json();
    }

    // ============ Cameras API ============

    /**
     * List cameras
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async listCameras(options = {}) {
        return this.request('GET', '/cameras', { query: options });
    }

    /**
     * Get camera by ID
     * @param {string} cameraId - Camera ID
     * @returns {Promise<Object>}
     */
    async getCamera(cameraId) {
        return this.request('GET', `/cameras/${cameraId}`);
    }

    /**
     * Add a new camera
     * @param {Object} camera - Camera configuration
     * @returns {Promise<Object>}
     */
    async addCamera(camera) {
        return this.request('POST', '/cameras', { body: camera });
    }

    /**
     * Update camera
     * @param {string} cameraId - Camera ID
     * @param {Object} camera - Camera configuration
     * @returns {Promise<Object>}
     */
    async updateCamera(cameraId, camera) {
        return this.request('PATCH', `/cameras/${cameraId}`, { body: camera });
    }

    /**
     * Delete camera
     * @param {string} cameraId - Camera ID
     * @returns {Promise<void>}
     */
    async deleteCamera(cameraId) {
        return this.request('DELETE', `/cameras/${cameraId}`);
    }

    // ============ Live Presets API ============

    /**
     * List live presets
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async listPresets(options = {}) {
        return this.request('GET', '/LivePresets', { query: options });
    }

    /**
     * Get preset by ID
     * @param {string} presetId - Preset ID
     * @returns {Promise<Object>}
     */
    async getPreset(presetId) {
        return this.request('GET', `/LivePresets/${presetId}`);
    }

    /**
     * Create preset
     * @param {Object} preset - Preset configuration
     * @returns {Promise<Object>}
     */
    async createPreset(preset) {
        return this.request('POST', '/LivePresets', { body: preset });
    }

    /**
     * Update preset
     * @param {string} presetId - Preset ID
     * @param {Object} preset - Preset configuration
     * @returns {Promise<Object>}
     */
    async updatePreset(presetId, preset) {
        return this.request('PUT', `/LivePresets/${presetId}`, { body: preset });
    }

    /**
     * Delete preset
     * @param {string} presetId - Preset ID
     * @returns {Promise<void>}
     */
    async deletePreset(presetId) {
        return this.request('DELETE', `/LivePresets/${presetId}`);
    }

    // ============ Custom Insights API ============

    /**
     * List custom insights
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async listCustomInsights(options = {}) {
        return this.request('GET', '/customInsights', { query: options });
    }

    /**
     * Get custom insight
     * @param {string} insightId - Insight ID
     * @returns {Promise<Object>}
     */
    async getCustomInsight(insightId) {
        return this.request('GET', `/customInsights/${insightId}`);
    }

    /**
     * Create custom insight
     * @param {Object} insight - Insight configuration
     * @returns {Promise<Object>}
     */
    async createCustomInsight(insight) {
        return this.request('POST', '/customInsights', { body: insight });
    }

    /**
     * Update custom insight
     * @param {string} insightId - Insight ID
     * @param {Object} insight - Insight configuration
     * @returns {Promise<Object>}
     */
    async updateCustomInsight(insightId, insight) {
        return this.request('PUT', `/customInsights/${insightId}`, { body: insight });
    }

    /**
     * Delete custom insight
     * @param {string} insightId - Insight ID
     * @returns {Promise<void>}
     */
    async deleteCustomInsight(insightId) {
        return this.request('DELETE', `/customInsights/${insightId}`);
    }

    // ============ Videos API ============

    /**
     * List videos
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async listVideos(options = {}) {
        return this.request('GET', '/Videos', { query: options });
    }

    /**
     * Get video
     * @param {string} videoId - Video ID
     * @returns {Promise<Object>}
     */
    async getVideo(videoId) {
        return this.request('GET', `/Videos/${videoId}`);
    }

    /**
     * Get video index
     * @param {string} videoId - Video ID
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async getVideoIndex(videoId, options = {}) {
        return this.request('GET', `/Videos/${videoId}/Index`, { query: options });
    }

    /**
     * Delete video
     * @param {string} videoId - Video ID
     * @returns {Promise<void>}
     */
    async deleteVideo(videoId) {
        return this.request('DELETE', `/Videos/${videoId}`);
    }

    /**
     * Search videos
     * @param {Object} searchRequest - Search parameters
     * @returns {Promise<Object>}
     */
    async searchVideos(searchRequest) {
        return this.request('POST', '/videos/search', { body: searchRequest });
    }

    // ============ Live Insights API ============

    /**
     * Get live insights for a camera
     * @param {string} cameraId - Camera ID
     * @param {Object} options - Query options (dateTime, includedInsightsTypes)
     * @returns {Promise<Object>}
     */
    async getLiveInsights(cameraId, options = {}) {
        return this.request('GET', `/Cameras/${cameraId}/Insights`, { query: options });
    }

    // ============ Spatial Analysis Rules API ============

    /**
     * List spatial analysis rules for a camera
     * @param {string} cameraId - Camera ID
     * @returns {Promise<Object>}
     */
    async listSpatialRules(cameraId) {
        return this.request('GET', `/cameras/${cameraId}/SpatialAnalysisRules`);
    }

    /**
     * Create spatial analysis rule
     * @param {string} cameraId - Camera ID
     * @param {Object} rule - Rule configuration
     * @returns {Promise<Object>}
     */
    async createSpatialRule(cameraId, rule) {
        return this.request('POST', `/cameras/${cameraId}/SpatialAnalysisRules`, { body: rule });
    }

    /**
     * Delete spatial analysis rule
     * @param {string} cameraId - Camera ID
     * @param {string} ruleId - Rule ID
     * @returns {Promise<void>}
     */
    async deleteSpatialRule(cameraId, ruleId) {
        return this.request('DELETE', `/cameras/${cameraId}/SpatialAnalysisRules/${ruleId}`);
    }

    // ============ Tags API ============

    /**
     * List tags
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async listTags(options = {}) {
        return this.request('GET', '/tags', { query: options });
    }

    /**
     * Create tag
     * @param {Object} tag - Tag configuration
     * @returns {Promise<Object>}
     */
    async createTag(tag) {
        return this.request('POST', '/tags', { body: tag });
    }

    /**
     * Delete tag
     * @param {string} tagId - Tag ID
     * @returns {Promise<void>}
     */
    async deleteTag(tagId) {
        return this.request('DELETE', `/tags/${tagId}`);
    }

    // ============ Summarization API ============

    /**
     * Create video summary
     * @param {string} videoId - Video ID
     * @param {Object} options - Summary options
     * @returns {Promise<Object>}
     */
    async createSummary(videoId, options = {}) {
        return this.request('POST', `/Videos/${videoId}/Summaries/Textual`, { query: options });
    }

    /**
     * Get video summary
     * @param {string} videoId - Video ID
     * @param {string} summaryId - Summary ID
     * @returns {Promise<Object>}
     */
    async getSummary(videoId, summaryId) {
        return this.request('GET', `/Videos/${videoId}/Summaries/Textual/${summaryId}`);
    }

    // ============ Agent Jobs API ============

    /**
     * List agent jobs
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async listAgentJobs(options = {}) {
        return this.request('GET', '/AgentJobs', { query: options });
    }

    /**
     * Create agent job
     * @param {Object} job - Job configuration
     * @returns {Promise<Object>}
     */
    async createAgentJob(job) {
        return this.request('POST', '/AgentJobs', { body: job });
    }

    /**
     * Get agent job
     * @param {string} jobId - Job ID
     * @returns {Promise<Object>}
     */
    async getAgentJob(jobId) {
        return this.request('GET', `/AgentJobs/${jobId}`);
    }

    /**
     * Update agent job
     * @param {string} jobId - Job ID
     * @param {Object} job - Job configuration
     * @returns {Promise<Object>}
     */
    async updateAgentJob(jobId, job) {
        return this.request('PUT', `/AgentJobs/${jobId}`, { body: job });
    }

    /**
     * Delete agent job
     * @param {string} jobId - Job ID
     * @returns {Promise<void>}
     */
    async deleteAgentJob(jobId) {
        return this.request('DELETE', `/AgentJobs/${jobId}`);
    }

    // ============ Chats API ============

    /**
     * Create chat
     * @returns {Promise<Object>}
     */
    async createChat() {
        return this.request('POST', '/chats');
    }

    /**
     * List chats
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async listChats(options = {}) {
        return this.request('GET', '/chats', { query: options });
    }

    /**
     * Send message to chat
     * @param {string} chatId - Chat ID
     * @param {Object} message - Message content
     * @returns {Promise<Object>}
     */
    async sendMessage(chatId, message) {
        return this.request('POST', `/chats/${chatId}/messages`, { body: message });
    }

    /**
     * Get chat messages
     * @param {string} chatId - Chat ID
     * @param {Object} options - Query options
     * @returns {Promise<Object>}
     */
    async getChatMessages(chatId, options = {}) {
        return this.request('GET', `/chats/${chatId}/messages`, { query: options });
    }
}

export default VideoIndexerClient;
