export interface AiartConfig {
    accessKeySecret: string;
    baseURL?: string;
    workspaceId?: string;
}
export type FileType = 'image' | 'video' | 'audio';
export type BusinessType = 2 | 4 | 5 | 6 | 8 | 10;
export interface StsCredentials {
    accessKeyId: string;
    accessKeySecret: string;
    securityToken: string;
    targetDir: string;
    targetFilename: string;
    host: string;
    provider: 'aliyun' | 'tencent';
}
export interface ResourceInfo {
    resourceId: string;
    resourceURL: string;
    thumbnailURL: string;
    metadata?: Record<string, unknown>;
}
export interface ResourceItem extends ResourceInfo {
    resourceType: string;
    width?: number;
    height?: number;
    duration?: number;
}
export type ArtSpecScope = 'community' | 'workspace' | 'shared';
export interface ArtSpecRelease {
    id: string;
    artSpecId: string;
    name: string;
    description: string;
    coverImage: ResourceItem;
    author: {
        userId: string;
        username: string;
        avatarURL: string;
    };
    version: number;
    releaseVersion: number;
    status: string;
    accessScope: string;
    releasedAt: number;
    createdAt: number;
    updatedAt: number;
}
export type ArtStyleQueryType = 'public' | 'shared';
export interface ArtStyle {
    id: string;
    workspaceId: string;
    name: string;
    description: string;
    accessScope: string;
    status: string;
    sourceType: string;
    triggerWord: string;
    loraWeight: number;
    loraBaseModel: string;
    loraProvider: string;
    coverImage: ResourceItem;
    isFavorite: boolean;
    isLike: boolean;
    author: {
        userId: string;
        username: string;
        avatarURL: string;
    };
    supportReferenceImage: boolean;
    characters?: {
        id: string;
        name: string;
        avatar: ResourceItem;
    }[];
}
export type ImageTaskType = 'general' | 'erase' | 'outpaint' | 'inpaint' | 'upscale' | 'creativeUpscale' | 'removeBackground' | 'outfitAnyone' | 'multiEdit';
export type AspectRatio = '9:16' | '2:3' | '3:4' | '4:5' | '1:1' | '16:9' | '3:2' | '4:3' | '5:4' | '21:9';
export interface ReferenceImage {
    purpose: 'source' | 'mask' | 'character' | 'fullGarment' | 'upperGarment' | 'bottomGarment';
    imageId: string;
    weight?: number;
    maskImageId?: string;
    maskImageURL?: string;
}
export interface OutpaintSize {
    left?: number;
    right?: number;
    top?: number;
    bottom?: number;
}
export interface OutfitControl {
    keepHand: boolean;
    keepFoot: boolean;
}
export interface GeneralImageParams {
    taskType: 'multiEdit';
    positivePrompt?: string;
    negativePrompt?: string;
    aspectRatio?: AspectRatio;
    width?: number;
    height?: number;
    artSpecIds?: string[];
    referenceImages?: ReferenceImage[];
    inferenceMode?: string;
    visualSubjects?: {
        name: string;
        references: ResourceItem[];
    }[];
}
export interface EraseParams {
    taskType: 'erase';
    referenceImages: [
        {
            imageId: string;
            weight: 1;
            purpose: 'source';
        },
        {
            imageId: string;
            weight: 1;
            purpose: 'mask';
        }
    ];
}
export interface OutpaintParams {
    taskType: 'outpaint';
    referenceImages: [{
        imageId: string;
        weight: 1;
        purpose: 'source';
    }];
    outpaintSize: OutpaintSize;
}
export interface InpaintParams {
    taskType: 'inpaint';
    positivePrompt: string;
    referenceImages: [
        {
            purpose: 'source';
            maskImageId: string;
            maskImageURL: string;
        },
        {
            purpose: 'mask';
        }
    ];
}
export interface UpscaleParams {
    taskType: 'upscale' | 'creativeUpscale';
    referenceImages: [{
        purpose: 'source';
        imageId: string;
        weight: 1;
    }];
    parentTaskType?: 'image';
    parentTaskId?: string;
    originArtifactId?: string;
}
export interface RemoveBackgroundParams {
    taskType: 'removeBackground';
    referenceImages: [{
        purpose: 'source';
        imageId: string;
        weight: 1;
    }];
}
export interface OutfitAnyoneParams {
    taskType: 'outfitAnyone';
    referenceImages: ReferenceImage[];
    width?: number;
    height?: number;
    outfitControl?: OutfitControl;
}
export interface MultiEditParams {
    taskType: 'multiEdit';
    positivePrompt?: string;
    referenceImages?: ReferenceImage[];
    artSpecIds?: string[];
}
export type ImageTaskParams = GeneralImageParams | EraseParams | OutpaintParams | InpaintParams | UpscaleParams | RemoveBackgroundParams | OutfitAnyoneParams | MultiEditParams;
export type ImageTaskStatus = 'pending' | 'in_progress' | 'completed' | 'failed' | 'abort';
export interface ImageTask {
    taskId: string;
    taskType: ImageTaskType;
    status: ImageTaskStatus;
    parameter: ImageTaskParams;
    artifacts?: ResourceItem[];
    createdAt: number;
    updatedAt: number;
}
export type VideoTaskType = 'generation' | 'multimodalGeneration' | 'extendByFrame' | 'audioDrivenLipSync' | 'driveImageWithAudio' | 'driveImageWithVideo' | 'videoSuperResolve' | 'videoInsertFrame' | 'reduceNoise' | 'enhancePortrait' | 'colorEnhance';
export type VideoInferenceMode = 'accurateMatch' | 'dynamicMotion';
export type VideoDuration = '5s' | '10s';
export type BodyProportionType = 'humanLike' | 'nonHuman';
export interface VideoReferenceResource {
    usageType: 'sourceVideo' | 'firstFrameImage' | 'tailFrameImage' | 'genericImage' | 'character' | 'motion' | 'driverAudio' | 'audio';
    resource: {
        resourceId: string;
        thumbnailURL?: string;
        width?: number;
        height?: number;
        resourceType: 'image' | 'video' | 'audio';
        crop?: {
            offset: number;
            duration: number;
        };
    };
}
export interface GenerationVideoParams {
    taskType: 'generation' | 'multimodalGeneration';
    prompt?: string;
    referenceResources?: VideoReferenceResource[];
    duration?: VideoDuration;
    aspectRatio?: AspectRatio;
    inferenceMode?: VideoInferenceMode;
    enableSound?: boolean;
    parentTaskId?: string;
    parentTaskType?: string;
    originArtifactId?: string;
}
export interface ExtendByFrameParams {
    taskType: 'extendByFrame';
    referenceResources: [
        {
            usageType: 'sourceVideo';
            resource: {
                resourceId: string;
                resourceType: 'image';
                crop?: {
                    offset: number;
                };
            };
        }
    ];
}
export interface LipSyncParams {
    taskType: 'audioDrivenLipSync' | 'driveImageWithAudio';
    referenceResources: [
        VideoReferenceResource,
        VideoReferenceResource
    ];
}
export interface DriveImageWithVideoParams {
    taskType: 'driveImageWithVideo';
    referenceResources: [
        {
            usageType: 'character';
            resource: {
                resourceId: string;
                resourceType: 'image';
                thumbnailURL?: string;
                width?: number;
                height?: number;
            };
        },
        {
            usageType: 'motion';
            resource: {
                resourceId: string;
                resourceType: 'video';
                thumbnailURL?: string;
                width?: number;
                height?: number;
            };
        }
    ];
    bodyProportionType: BodyProportionType;
}
export interface VideoPostProcessParams {
    taskType: 'videoSuperResolve' | 'videoInsertFrame' | 'reduceNoise' | 'enhancePortrait' | 'colorEnhance';
    referenceResources: [
        {
            usageType: 'sourceVideo';
            resource: {
                resourceId: string;
                resourceType: 'video';
                thumbnailURL?: string;
            };
        }
    ];
    parentTaskId?: string;
    parentTaskType?: 'video';
    originArtifactId?: string;
    superResolveMode?: 'pro';
}
export type VideoTaskParams = GenerationVideoParams | ExtendByFrameParams | LipSyncParams | DriveImageWithVideoParams | VideoPostProcessParams;
export type VideoTaskStatus = 'pending' | 'in_progress' | 'completed' | 'failed' | 'abort';
export interface VideoTask {
    id: string;
    taskType: VideoTaskType;
    status: VideoTaskStatus;
    parameter: VideoTaskParams;
    artifacts?: (ResourceItem & {
        videoResource?: ResourceItem;
    })[];
    createdAt: number;
    updatedAt: number;
}
export interface Conversation {
    conversationId: string;
    chatId: string;
    status: 'in_progress' | 'completed' | 'failed';
    userInput: {
        prompt: string;
        referenceResources: VideoReferenceResource[];
    };
    answer: {
        content: string;
        reasoningContent: string;
    };
}
export type ThreeDActionType = 'generation' | 'simplify';
export type RenderStyle = 'whiteModel' | 'textured';
export type MeshLevel = 'low' | 'medium' | 'high' | 'ultra';
export type PolygonType = 'triangle' | 'quad';
export type ViewType = 'front' | 'back' | 'left' | 'right' | 'auto';
export type RunningTaskType = 'none' | 'modelGeneration' | 'simplify' | 'imageEnhancement';
export interface ThreeDInputImage {
    imageId: string;
    viewType: ViewType;
}
export interface ThreeDGenerationParameter {
    sourceType: 'user';
    prompt?: string;
    imageEnhancement: boolean;
    renderStyle: RenderStyle;
    meshLevel: MeshLevel;
    lowPoly: boolean;
    polygonType?: PolygonType;
    inputImages?: ThreeDInputImage[];
}
export interface ThreeDSimplifyParameter {
    polygonType: PolygonType;
}
export interface ThreeDProject {
    projectId: string;
    name?: string;
    coverImage?: ResourceItem;
    runningTaskType: RunningTaskType;
    latestAction?: {
        actionId: string;
        actionType: ThreeDActionType;
        status?: string;
    };
    metadata?: {
        prompt?: string;
        inputImages?: ResourceItem[];
    };
    createdAt: number;
    updatedAt: number;
}
export interface ThreeDProjectCreateParams {
    name?: string;
    sourceType?: 'user';
    prompt?: string;
    imageEnhancement?: boolean;
    renderStyle?: RenderStyle;
    meshLevel?: MeshLevel;
    lowPoly?: boolean;
    polygonType?: PolygonType;
    inputImages?: ThreeDInputImage[];
}
export interface PageInfo {
    hasMore: boolean;
    nextPageToken: string;
}
export interface PagedResponse<T> {
    list: T[];
    pageInfo: PageInfo;
}
export interface UserInfo {
    userId: string;
    profile: {
        username: string;
    };
    localization: string;
}
export interface Workspace {
    workspaceId: string;
    serviceCode: string;
    name: string;
}
export interface AiartConfigurations {
    assistantTemplateId: string;
    promptExpansionTemplateId: string;
    imageContentReverseTemplateId: string;
    concurrentTaskLimit: {
        imageGeneration: number;
        videoGeneration: number;
    };
}
