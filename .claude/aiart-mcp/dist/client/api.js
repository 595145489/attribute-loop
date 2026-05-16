import axios from 'axios';
import path from 'path';
import { uploadToOSS, getMimeType, readFileBuffer } from './upload.js';
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
export class AiartClient {
    http;
    workspaceId;
    constructor(config) {
        this.http = axios.create({
            baseURL: config.baseURL ?? 'https://aiart.happyelements.com',
            headers: { Authorization: `Bearer ${config.accessKeySecret}` },
        });
        this.workspaceId = config.workspaceId ?? '';
    }
    handleAxiosError(err) {
        if (axios.isAxiosError(err)) {
            const e = err;
            if (e.response) {
                const d = e.response.data;
                const msg = d?.message ?? d?.msg ?? JSON.stringify(d);
                throw new Error(`AIART HTTP ${e.response.status}: ${msg}`);
            }
        }
        throw err;
    }
    // Returns data directly (for endpoints that return the payload at data level)
    async get(url, params) {
        try {
            const res = await this.http.get(url, { params });
            const { code, message, data } = res.data;
            if (code !== 0)
                throw new Error(`AIART ${code}: ${message}`);
            return data;
        }
        catch (err) {
            this.handleAxiosError(err);
        }
    }
    async post(url, body) {
        try {
            const res = await this.http.post(url, body);
            const { code, message, data } = res.data;
            if (code !== 0)
                throw new Error(`AIART ${code}: ${message}`);
            return data;
        }
        catch (err) {
            this.handleAxiosError(err);
        }
    }
    // Unwraps data.info (common response envelope)
    async getInfo(url, params) {
        const d = await this.get(url, params);
        return d.info;
    }
    async postInfo(url, body) {
        const d = await this.post(url, body);
        return d.info;
    }
    wsBase() {
        return `/api/v1/ai-fusion/workspaces/${this.workspaceId}`;
    }
    threeDBase() {
        return `/api/v1/three-studio/workspaces/${this.workspaceId}`;
    }
    // ── User / Workspace ─────────────────────────────────────────────────────
    async getUser() {
        const d = await this.get('/api/v1/passport/me');
        return d.userInfo;
    }
    async getWorkspaces() {
        const d = await this.get('/api/v1/workspace/services/ai-fusion/workspaces');
        return d.list;
    }
    async getConfigurations() {
        return this.getInfo('/api/v1/ai-fusion/configurations');
    }
    // ── Upload ────────────────────────────────────────────────────────────────
    async assumeUploadRoles(fileType, businessType = 2, extensionName) {
        return this.getInfo('/api/v1/resource/uploads/assume-roles', {
            serviceCode: 'ai-fusion',
            workspaceId: this.workspaceId,
            fileType,
            businessType,
            ...(extensionName ? { extensionName } : {}),
        });
    }
    async registerUpload(params) {
        return this.postInfo(`/api/v1/resource/services/ai-fusion/workspaces/${this.workspaceId}/resources`, params);
    }
    async uploadFile(filePath, fileType, businessType = 2) {
        const ext = path.extname(filePath).toLowerCase().replace('.', '') || fileType;
        const sts = await this.assumeUploadRoles(fileType, businessType, ext);
        const fileBuffer = readFileBuffer(filePath);
        const mimeType = getMimeType(filePath, fileType);
        const etag = await uploadToOSS(sts, fileBuffer, mimeType);
        const dir = sts.targetDir.endsWith('/') ? sts.targetDir : `${sts.targetDir}/`;
        const uploadPath = dir + sts.targetFilename;
        const originalFileName = path.basename(filePath);
        return this.registerUpload({ fileType, businessType, uploadPath, etag, attribute: {}, originalFileName });
    }
    // ── Art Styles ────────────────────────────────────────────────────────────
    async listArtStyles(queryType = 'public', pageToken, pageSize = 20) {
        return this.get(`${this.wsBase()}/art-styles`, {
            queryType,
            ...(pageToken ? { pageToken } : {}),
            pageSize,
        });
    }
    // ── Art Specs ─────────────────────────────────────────────────────────────
    async listArtSpecReleases(scope, pageToken, pageSize = 20) {
        const pagination = { ...(pageToken ? { pageToken } : {}), pageSize };
        if (scope === 'community') {
            return this.get('/api/v1/ai-fusion/community/art-specs/releases', pagination);
        }
        if (scope === 'workspace') {
            return this.get(`${this.wsBase()}/art-specs/available-releases`, pagination);
        }
        // shared
        return this.get(`${this.wsBase()}/art-specs/shared-releases`, pagination);
    }
    // ── Image Tasks ───────────────────────────────────────────────────────────
    async createImageTask(params) {
        return this.postInfo(`${this.wsBase()}/imagines/generations`, params);
    }
    async getImageTask(taskId) {
        return this.getInfo(`${this.wsBase()}/imagines/${taskId}`);
    }
    async listImageTasks(pageToken, pageSize = 20) {
        const d = await this.get(`${this.wsBase()}/inference-tasks`, {
            ...(pageToken ? { pageToken } : {}),
            pageSize,
        });
        const list = d.list.filter((x) => !!x.imageTaskInfo).map((x) => x.imageTaskInfo);
        return { list, pageInfo: d.pageInfo };
    }
    async pollImageTask(taskId, opts = {}) {
        const { intervalMs = 3000, timeoutMs = 300_000 } = opts;
        const deadline = Date.now() + timeoutMs;
        while (Date.now() < deadline) {
            const task = await this.getImageTask(taskId);
            if (task.status === 'completed' || task.status === 'failed' || task.status === 'abort') {
                return task;
            }
            await sleep(Math.min(intervalMs, deadline - Date.now()));
        }
        throw new Error(`Image task ${taskId} timed out after ${timeoutMs}ms`);
    }
    // ── Video Tasks ───────────────────────────────────────────────────────────
    async createVideoTask(params) {
        // snippets[] is required by the API for generation tasks
        const body = { snippets: [], ...params };
        return this.postInfo(`${this.wsBase()}/video-generations`, body);
    }
    async getVideoTask(taskId) {
        return this.getInfo(`${this.wsBase()}/video-generations/${taskId}`);
    }
    async listVideoTasks(pageToken, pageSize = 20) {
        const d = await this.get(`${this.wsBase()}/inference-tasks`, {
            ...(pageToken ? { pageToken } : {}),
            pageSize,
        });
        const list = d.list.filter((x) => !!x.videoTaskInfo).map((x) => x.videoTaskInfo);
        return { list, pageInfo: d.pageInfo };
    }
    async pollVideoTask(taskId, opts = {}) {
        const { intervalMs = 5000, timeoutMs = 600_000 } = opts;
        const deadline = Date.now() + timeoutMs;
        while (Date.now() < deadline) {
            const task = await this.getVideoTask(taskId);
            if (task.status === 'completed' || task.status === 'failed' || task.status === 'abort') {
                return task;
            }
            await sleep(Math.min(intervalMs, deadline - Date.now()));
        }
        throw new Error(`Video task ${taskId} timed out after ${timeoutMs}ms`);
    }
    // ── Conversations ─────────────────────────────────────────────────────────
    async createConversation(input) {
        return this.postInfo(`${this.wsBase()}/conversations`, input);
    }
    async getConversation(conversationId) {
        return this.getInfo(`${this.wsBase()}/conversations/${conversationId}`);
    }
    async pollConversation(conversationId, opts = {}) {
        const { intervalMs = 2000, timeoutMs = 120_000 } = opts;
        const deadline = Date.now() + timeoutMs;
        while (Date.now() < deadline) {
            const conv = await this.getConversation(conversationId);
            if (conv.status === 'completed' || conv.status === 'failed') {
                return conv;
            }
            await sleep(Math.min(intervalMs, deadline - Date.now()));
        }
        throw new Error(`Conversation ${conversationId} timed out after ${timeoutMs}ms`);
    }
    // ── 3D Studio ─────────────────────────────────────────────────────────────
    async createThreeDProject(params = {}) {
        const body = { sourceType: 'user', ...params };
        const project = await this.postInfo(`${this.threeDBase()}/projects`, body);
        // POST response omits latestAction; fetch the full project to get actionId
        return this.getThreeDProject(project.projectId);
    }
    async getThreeDProject(projectId) {
        return this.getInfo(`${this.threeDBase()}/projects/${projectId}`);
    }
    async listThreeDProjects(pageToken, pageSize = 20) {
        return this.get(`${this.threeDBase()}/projects`, {
            ...(pageToken ? { pageToken } : {}),
            pageSize,
        });
    }
    async pollThreeDProject(projectId, opts = {}) {
        const { intervalMs = 5000, timeoutMs = 600_000 } = opts;
        const deadline = Date.now() + timeoutMs;
        while (Date.now() < deadline) {
            const project = await this.getThreeDProject(projectId);
            if (!project.runningTaskType || project.runningTaskType === 'none')
                return project;
            await sleep(Math.min(intervalMs, deadline - Date.now()));
        }
        throw new Error(`3D project ${projectId} timed out after ${timeoutMs}ms`);
    }
}
//# sourceMappingURL=api.js.map