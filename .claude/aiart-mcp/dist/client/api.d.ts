import type { AiartConfig, AiartConfigurations, ArtSpecRelease, ArtSpecScope, ArtStyle, ArtStyleQueryType, BusinessType, Conversation, FileType, ImageTask, ImageTaskParams, PagedResponse, ResourceInfo, StsCredentials, ThreeDProject, ThreeDProjectCreateParams, UserInfo, VideoReferenceResource, VideoTask, VideoTaskParams, Workspace } from './types.js';
export declare class AiartClient {
    private http;
    readonly workspaceId: string;
    constructor(config: AiartConfig);
    private handleAxiosError;
    private get;
    private post;
    private getInfo;
    private postInfo;
    private wsBase;
    private threeDBase;
    getUser(): Promise<UserInfo>;
    getWorkspaces(): Promise<Workspace[]>;
    getConfigurations(): Promise<AiartConfigurations>;
    assumeUploadRoles(fileType: FileType, businessType?: BusinessType, extensionName?: string): Promise<StsCredentials>;
    registerUpload(params: {
        fileType: FileType;
        businessType: BusinessType;
        uploadPath: string;
        etag: string;
        attribute: Record<string, unknown>;
        originalFileName: string;
    }): Promise<ResourceInfo>;
    uploadFile(filePath: string, fileType: FileType, businessType?: BusinessType): Promise<ResourceInfo>;
    listArtStyles(queryType?: ArtStyleQueryType, pageToken?: string, pageSize?: number): Promise<PagedResponse<ArtStyle>>;
    listArtSpecReleases(scope: ArtSpecScope, pageToken?: string, pageSize?: number): Promise<PagedResponse<ArtSpecRelease>>;
    createImageTask(params: ImageTaskParams): Promise<ImageTask>;
    getImageTask(taskId: string): Promise<ImageTask>;
    listImageTasks(pageToken?: string, pageSize?: number): Promise<PagedResponse<ImageTask>>;
    pollImageTask(taskId: string, opts?: {
        intervalMs?: number;
        timeoutMs?: number;
    }): Promise<ImageTask>;
    createVideoTask(params: VideoTaskParams): Promise<VideoTask>;
    getVideoTask(taskId: string): Promise<VideoTask>;
    listVideoTasks(pageToken?: string, pageSize?: number): Promise<PagedResponse<VideoTask>>;
    pollVideoTask(taskId: string, opts?: {
        intervalMs?: number;
        timeoutMs?: number;
    }): Promise<VideoTask>;
    createConversation(input: {
        prompt: string;
        referenceResources?: VideoReferenceResource[];
    }): Promise<Conversation>;
    getConversation(conversationId: string): Promise<Conversation>;
    pollConversation(conversationId: string, opts?: {
        intervalMs?: number;
        timeoutMs?: number;
    }): Promise<Conversation>;
    createThreeDProject(params?: ThreeDProjectCreateParams): Promise<ThreeDProject>;
    getThreeDProject(projectId: string): Promise<ThreeDProject>;
    listThreeDProjects(pageToken?: string, pageSize?: number): Promise<PagedResponse<ThreeDProject>>;
    pollThreeDProject(projectId: string, opts?: {
        intervalMs?: number;
        timeoutMs?: number;
    }): Promise<ThreeDProject>;
}
