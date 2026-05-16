#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema, } from '@modelcontextprotocol/sdk/types.js';
import { AiartClient } from '../client/api.js';
// ── Config ────────────────────────────────────────────────────────────────────
const accessKey = process.env.AIART_ACCESS_KEY;
const workspaceId = process.env.AIART_WORKSPACE_ID;
const baseURL = process.env.AIART_BASE_URL;
if (!accessKey) {
    process.stderr.write('AIART_ACCESS_KEY environment variable is required\n');
    process.exit(1);
}
if (!workspaceId) {
    process.stderr.write('AIART_WORKSPACE_ID environment variable is required\n');
    process.exit(1);
}
const client = new AiartClient({ accessKeySecret: accessKey, workspaceId, baseURL });
// ── Tool Definitions ──────────────────────────────────────────────────────────
const TOOLS = [
    {
        name: 'upload_file',
        description: 'Upload a local file (image, video, or audio) to AIART storage. Returns a resourceId and URL that can be used as referenceImages or referenceResources in generation tasks.',
        inputSchema: {
            type: 'object',
            properties: {
                filePath: { type: 'string', description: 'Absolute path to the local file to upload.' },
                fileType: {
                    type: 'string',
                    enum: ['image', 'video', 'audio'],
                    description: 'Type of the file being uploaded.',
                },
                businessType: {
                    type: 'number',
                    enum: [2, 4, 5, 6, 8, 10],
                    description: 'Storage business type: 2=default, 8=reference/style image, 10=mask, 4=image output, 5=video output, 6=thumbnail. Default: 2.',
                },
            },
            required: ['filePath', 'fileType'],
        },
    },
    {
        name: 'list_art_styles',
        description: 'List available art styles (trained LoRA models). Use queryType "public" for community styles or "shared" for styles shared to your workspace. Returns style id, name, description, triggerWord, and loraBaseModel.',
        inputSchema: {
            type: 'object',
            properties: {
                queryType: {
                    type: 'string',
                    enum: ['public', 'shared'],
                    description: 'Which art styles to list. Default: "public".',
                },
                pageToken: { type: 'string', description: 'Pagination cursor from a previous response.' },
                pageSize: { type: 'number', description: 'Number of results per page. Default: 20.' },
            },
        },
    },
    {
        name: 'list_art_specs',
        description: 'List art spec releases (art packs / style bundles). Scope "community" shows public packs, "workspace" shows packs in your workspace, "shared" shows packs shared with you. Returns pack id, name, and description.',
        inputSchema: {
            type: 'object',
            properties: {
                scope: {
                    type: 'string',
                    enum: ['community', 'workspace', 'shared'],
                    description: 'Which art specs to list. Default: "community".',
                },
                pageToken: { type: 'string', description: 'Pagination cursor from a previous response.' },
                pageSize: { type: 'number', description: 'Number of results per page. Default: 20.' },
            },
        },
    },
    {
        name: 'create_image_task',
        description: `Create an image generation or editing task.

taskType options and required params:
- "general": positivePrompt required; optionally negativePrompt, aspectRatio, width, height, artSpecIds (art pack IDs), referenceImages (for style/character reference).
- "erase": referenceImages with one source image (purpose:"source") and one mask (purpose:"mask").
- "outpaint": referenceImages with one source image (purpose:"source"); outpaintSize with left/right/top/bottom pixel amounts.
- "inpaint": positivePrompt required; referenceImages with source (purpose:"source", maskImageId, maskImageURL) and mask (purpose:"mask").
- "upscale" / "creativeUpscale": referenceImages with one source image (purpose:"source", weight:1).
- "removeBackground": referenceImages with one source image (purpose:"source", weight:1).
- "outfitAnyone": referenceImages with one character image (purpose:"character") and garment images (purpose:"fullGarment", "upperGarment", or "bottomGarment").
- "multiEdit": referenceImages array; optionally positivePrompt and artSpecIds.

Set waitForCompletion:false to return immediately with a taskId for polling via check_image_task.`,
        inputSchema: {
            type: 'object',
            properties: {
                taskType: {
                    type: 'string',
                    enum: [
                        'general', 'erase', 'outpaint', 'inpaint',
                        'upscale', 'creativeUpscale', 'removeBackground',
                        'outfitAnyone', 'multiEdit',
                    ],
                },
                positivePrompt: { type: 'string' },
                negativePrompt: { type: 'string' },
                aspectRatio: {
                    type: 'string',
                    enum: ['9:16', '2:3', '3:4', '4:5', '1:1', '16:9', '3:2', '4:3', '5:4', '21:9'],
                },
                width: { type: 'number' },
                height: { type: 'number' },
                artSpecIds: { type: 'array', items: { type: 'string' }, description: 'Art pack IDs to apply.' },
                referenceImages: {
                    type: 'array',
                    description: 'Reference images for the task.',
                    items: {
                        type: 'object',
                        properties: {
                            purpose: {
                                type: 'string',
                                enum: ['source', 'mask', 'character', 'fullGarment', 'upperGarment', 'bottomGarment'],
                            },
                            imageId: { type: 'string' },
                            weight: { type: 'number' },
                            maskImageId: { type: 'string' },
                            maskImageURL: { type: 'string' },
                        },
                        required: ['purpose', 'imageId'],
                    },
                },
                outpaintSize: {
                    type: 'object',
                    description: 'Pixel amounts to expand in each direction (for outpaint task).',
                    properties: {
                        left: { type: 'number' },
                        right: { type: 'number' },
                        top: { type: 'number' },
                        bottom: { type: 'number' },
                    },
                },
                outfitControl: {
                    type: 'object',
                    description: 'Outfit-anyone control flags.',
                    properties: {
                        keepHand: { type: 'boolean' },
                        keepFoot: { type: 'boolean' },
                    },
                    required: ['keepHand', 'keepFoot'],
                },
                waitForCompletion: {
                    type: 'boolean',
                    description: 'Poll until the task finishes and return artifacts. Default: true.',
                },
                timeoutMs: {
                    type: 'number',
                    description: 'Max milliseconds to wait when polling. Default: 300000 (5 min).',
                },
            },
            required: ['taskType'],
        },
    },
    {
        name: 'check_image_task',
        description: 'Get the current status and results of an image task by its ID.',
        inputSchema: {
            type: 'object',
            properties: {
                taskId: { type: 'string', description: 'The image task ID.' },
                poll: {
                    type: 'boolean',
                    description: 'If true, poll until the task is done. Default: false.',
                },
                timeoutMs: { type: 'number', description: 'Max polling timeout in ms. Default: 300000.' },
            },
            required: ['taskId'],
        },
    },
    {
        name: 'list_image_tasks',
        description: 'List recent image tasks in the workspace.',
        inputSchema: {
            type: 'object',
            properties: {
                pageToken: { type: 'string' },
                pageSize: { type: 'number', description: 'Default: 20.' },
            },
        },
    },
    {
        name: 'create_video_task',
        description: `Create a video generation or processing task.

taskType options:
- "generation" / "multimodalGeneration": text-to-video or image-to-video. Use positivePrompt and/or referenceResources (usageType "genericImage" for reference images). duration: "5s"|"10s". inferenceMode: "dynamicMotion"|"accurateMatch".
- "extendByFrame": extend a video by one frame. referenceResources with usageType "sourceVideo" and resourceType "image" (the frame).
- "audioDrivenLipSync": drive a video's lip sync with audio. referenceResources: sourceVideo + driverAudio.
- "driveImageWithAudio": animate a portrait image with audio. referenceResources: character (image) + driverAudio.
- "driveImageWithVideo": animate a character image using a motion video. referenceResources: character (image) + motion (video). bodyProportionType: "humanLike"|"nonHuman".
- "videoSuperResolve": upscale video resolution. referenceResources: sourceVideo. Use superResolveMode:"pro" for highest quality.
- "videoInsertFrame" / "reduceNoise" / "enhancePortrait" / "colorEnhance": video post-processing. referenceResources: sourceVideo.

Set waitForCompletion:false to return immediately with taskId for polling via check_video_task.`,
        inputSchema: {
            type: 'object',
            properties: {
                taskType: {
                    type: 'string',
                    enum: [
                        'generation', 'multimodalGeneration', 'extendByFrame',
                        'audioDrivenLipSync', 'driveImageWithAudio', 'driveImageWithVideo',
                        'videoSuperResolve', 'videoInsertFrame', 'reduceNoise',
                        'enhancePortrait', 'colorEnhance',
                    ],
                },
                positivePrompt: { type: 'string', description: 'Text prompt for video generation.' },
                referenceResources: {
                    type: 'array',
                    description: 'Reference resources (images, videos, audio) for the task.',
                    items: {
                        type: 'object',
                        properties: {
                            usageType: {
                                type: 'string',
                                enum: [
                                    'sourceVideo', 'firstFrameImage', 'tailFrameImage',
                                    'genericImage', 'character', 'motion', 'driverAudio', 'audio',
                                ],
                            },
                            resource: {
                                type: 'object',
                                properties: {
                                    resourceId: { type: 'string' },
                                    resourceType: { type: 'string', enum: ['image', 'video', 'audio'] },
                                    thumbnailURL: { type: 'string' },
                                    width: { type: 'number' },
                                    height: { type: 'number' },
                                    crop: {
                                        type: 'object',
                                        properties: {
                                            offset: { type: 'number' },
                                            duration: { type: 'number' },
                                        },
                                    },
                                },
                                required: ['resourceId', 'resourceType'],
                            },
                        },
                        required: ['usageType', 'resource'],
                    },
                },
                duration: { type: 'string', enum: ['5s', '10s'], description: 'Video duration for generation tasks.' },
                aspectRatio: {
                    type: 'string',
                    enum: ['9:16', '2:3', '3:4', '4:5', '1:1', '16:9', '3:2', '4:3', '5:4', '21:9'],
                },
                inferenceMode: {
                    type: 'string',
                    enum: ['accurateMatch', 'dynamicMotion'],
                    description: 'Only for generation/multimodalGeneration. Default: "dynamicMotion".',
                },
                enableSound: { type: 'boolean', description: 'Generate audio alongside video.' },
                bodyProportionType: {
                    type: 'string',
                    enum: ['humanLike', 'nonHuman'],
                    description: 'For driveImageWithVideo only.',
                },
                superResolveMode: {
                    type: 'string',
                    enum: ['pro'],
                    description: 'For videoSuperResolve: use "pro" for highest quality.',
                },
                parentTaskId: { type: 'string', description: 'ID of the parent task (for re-edit flows).' },
                parentTaskType: { type: 'string' },
                originArtifactId: { type: 'string' },
                waitForCompletion: {
                    type: 'boolean',
                    description: 'Poll until done and return artifacts. Default: true.',
                },
                timeoutMs: {
                    type: 'number',
                    description: 'Max milliseconds to wait. Default: 600000 (10 min).',
                },
            },
            required: ['taskType'],
        },
    },
    {
        name: 'check_video_task',
        description: 'Get the current status and results of a video task by its ID.',
        inputSchema: {
            type: 'object',
            properties: {
                taskId: { type: 'string', description: 'The video task ID.' },
                poll: {
                    type: 'boolean',
                    description: 'If true, poll until the task is done. Default: false.',
                },
                timeoutMs: { type: 'number', description: 'Max polling timeout in ms. Default: 600000.' },
            },
            required: ['taskId'],
        },
    },
    {
        name: 'list_video_tasks',
        description: 'List recent video tasks in the workspace.',
        inputSchema: {
            type: 'object',
            properties: {
                pageToken: { type: 'string' },
                pageSize: { type: 'number', description: 'Default: 20.' },
            },
        },
    },
    {
        name: 'create_3d_project',
        description: `Create a 3D generation project and trigger a generation action.

Provide either a prompt (text-to-3D) or inputImages (image-to-3D), or both.
inputImages: array of { imageId, viewType } where viewType is "front"|"back"|"left"|"right"|"auto".
renderStyle: "textured" produces a textured mesh; "whiteModel" produces an untextured white mesh.
meshLevel: controls polygon density — "low"|"medium"|"high"|"ultra".
imageEnhancement: pre-enhances input images before generation (recommended: true).

Returns projectId, actionId, and final status/results when waitForCompletion is true.`,
        inputSchema: {
            type: 'object',
            properties: {
                prompt: { type: 'string', description: 'Text prompt for text-to-3D generation.' },
                renderStyle: {
                    type: 'string',
                    enum: ['whiteModel', 'textured'],
                    description: 'Default: "textured".',
                },
                meshLevel: {
                    type: 'string',
                    enum: ['low', 'medium', 'high', 'ultra'],
                    description: 'Polygon density. Default: "medium".',
                },
                lowPoly: {
                    type: 'boolean',
                    description: 'Generate a low-poly style mesh. Default: false.',
                },
                imageEnhancement: {
                    type: 'boolean',
                    description: 'Pre-enhance input images. Default: true.',
                },
                polygonType: {
                    type: 'string',
                    enum: ['triangle', 'quad'],
                },
                inputImages: {
                    type: 'array',
                    description: 'Images for image-to-3D generation.',
                    items: {
                        type: 'object',
                        properties: {
                            imageId: { type: 'string' },
                            viewType: { type: 'string', enum: ['front', 'back', 'left', 'right', 'auto'] },
                        },
                        required: ['imageId', 'viewType'],
                    },
                },
                projectName: { type: 'string', description: 'Optional name for the project.' },
                waitForCompletion: {
                    type: 'boolean',
                    description: 'Poll until done and return final status. Default: true.',
                },
                timeoutMs: {
                    type: 'number',
                    description: 'Max milliseconds to wait. Default: 600000 (10 min).',
                },
            },
        },
    },
    {
        name: 'check_3d_project',
        description: 'Get the current status of a 3D project.',
        inputSchema: {
            type: 'object',
            properties: {
                projectId: { type: 'string' },
                poll: {
                    type: 'boolean',
                    description: 'If true, poll until generation is done. Default: false.',
                },
                timeoutMs: { type: 'number', description: 'Max polling timeout in ms. Default: 600000.' },
            },
            required: ['projectId'],
        },
    },
    {
        name: 'chat',
        description: 'Start an AI conversation (the AIART assistant) with a text prompt and optional reference resources (images or videos). Polls until the answer is ready and returns the response text.',
        inputSchema: {
            type: 'object',
            properties: {
                prompt: { type: 'string', description: 'The user message / question.' },
                referenceResources: {
                    type: 'array',
                    description: 'Optional images or videos to include in the conversation.',
                    items: {
                        type: 'object',
                        properties: {
                            usageType: { type: 'string' },
                            resource: {
                                type: 'object',
                                properties: {
                                    resourceId: { type: 'string' },
                                    resourceType: { type: 'string', enum: ['image', 'video', 'audio'] },
                                },
                                required: ['resourceId', 'resourceType'],
                            },
                        },
                        required: ['usageType', 'resource'],
                    },
                },
                timeoutMs: {
                    type: 'number',
                    description: 'Max milliseconds to wait for an answer. Default: 120000 (2 min).',
                },
            },
            required: ['prompt'],
        },
    },
];
async function handleUploadFile(args) {
    const { filePath, fileType, businessType } = args;
    const info = await client.uploadFile(filePath, fileType, businessType ?? 2);
    return { resourceId: info.resourceId, resourceURL: info.resourceURL, thumbnailURL: info.thumbnailURL };
}
async function handleListArtStyles(args) {
    const result = await client.listArtStyles(args.queryType ?? 'public', args.pageToken, args.pageSize ?? 20);
    return {
        styles: result.list.map((s) => ({
            id: s.id,
            name: s.name,
            description: s.description,
            triggerWord: s.triggerWord,
            loraBaseModel: s.loraBaseModel,
            accessScope: s.accessScope,
            supportReferenceImage: s.supportReferenceImage,
        })),
        pageInfo: result.pageInfo,
    };
}
async function handleListArtSpecs(args) {
    const result = await client.listArtSpecReleases(args.scope ?? 'community', args.pageToken, args.pageSize ?? 20);
    return {
        specs: result.list.map((s) => ({
            id: s.id,
            artSpecId: s.artSpecId,
            name: s.name,
            description: s.description,
            version: s.releaseVersion,
            status: s.status,
        })),
        pageInfo: result.pageInfo,
    };
}
async function handleCreateImageTask(args) {
    const { waitForCompletion = true, timeoutMs = 300_000, ...rest } = args;
    const params = buildImageTaskParams(rest);
    const task = await client.createImageTask(params);
    if (!waitForCompletion) {
        return { taskId: task.taskId, status: task.status };
    }
    const done = await client.pollImageTask(task.taskId, { timeoutMs: timeoutMs });
    return formatImageTask(done);
}
async function handleCheckImageTask(args) {
    const { taskId, poll = false, timeoutMs = 300_000 } = args;
    const task = poll
        ? await client.pollImageTask(taskId, { timeoutMs: timeoutMs })
        : await client.getImageTask(taskId);
    return formatImageTask(task);
}
async function handleListImageTasks(args) {
    const result = await client.listImageTasks(args.pageToken, args.pageSize ?? 20);
    return {
        tasks: result.list.map((t) => ({ taskId: t.taskId, taskType: t.taskType, status: t.status, createdAt: t.createdAt })),
        pageInfo: result.pageInfo,
    };
}
async function handleCreateVideoTask(args) {
    const { waitForCompletion = true, timeoutMs = 600_000, ...rest } = args;
    const params = buildVideoTaskParams(rest);
    const task = await client.createVideoTask(params);
    if (!waitForCompletion) {
        return { taskId: task.id, status: task.status };
    }
    const done = await client.pollVideoTask(task.id, { timeoutMs: timeoutMs });
    return formatVideoTask(done);
}
async function handleCheckVideoTask(args) {
    const { taskId, poll = false, timeoutMs = 600_000 } = args;
    const task = poll
        ? await client.pollVideoTask(taskId, { timeoutMs: timeoutMs })
        : await client.getVideoTask(taskId);
    return formatVideoTask(task);
}
async function handleListVideoTasks(args) {
    const result = await client.listVideoTasks(args.pageToken, args.pageSize ?? 20);
    return {
        tasks: result.list.map((t) => ({ taskId: t.id, taskType: t.taskType, status: t.status, createdAt: t.createdAt })),
        pageInfo: result.pageInfo,
    };
}
async function handleCreate3DProject(args) {
    const { prompt, renderStyle = 'textured', meshLevel = 'medium', lowPoly = false, imageEnhancement = true, polygonType, inputImages, projectName, waitForCompletion = true, timeoutMs = 600_000, } = args;
    const params = {
        ...(projectName ? { name: projectName } : {}),
        sourceType: 'user',
        ...(prompt ? { prompt: prompt } : {}),
        imageEnhancement: imageEnhancement,
        renderStyle: renderStyle,
        meshLevel: meshLevel,
        lowPoly: lowPoly,
        ...(polygonType ? { polygonType: polygonType } : {}),
        ...(inputImages ? { inputImages: inputImages } : {}),
    };
    const project = await client.createThreeDProject(params);
    if (!waitForCompletion) {
        return {
            projectId: project.projectId,
            actionId: project.latestAction?.actionId,
            runningTaskType: project.runningTaskType,
        };
    }
    const done = await client.pollThreeDProject(project.projectId, { timeoutMs: timeoutMs });
    return {
        projectId: done.projectId,
        actionId: done.latestAction?.actionId,
        runningTaskType: done.runningTaskType,
        status: 'completed',
    };
}
async function handleCheck3DProject(args) {
    const { projectId, poll = false, timeoutMs = 600_000 } = args;
    const project = poll
        ? await client.pollThreeDProject(projectId, { timeoutMs: timeoutMs })
        : await client.getThreeDProject(projectId);
    return {
        projectId: project.projectId,
        actionId: project.latestAction?.actionId,
        runningTaskType: project.runningTaskType,
        status: project.runningTaskType === 'none' ? 'completed' : 'in_progress',
    };
}
async function handleChat(args) {
    const { prompt, referenceResources, timeoutMs = 120_000 } = args;
    const conv = await client.createConversation({
        prompt: prompt,
        referenceResources: referenceResources,
    });
    const done = await client.pollConversation(conv.conversationId, { timeoutMs: timeoutMs });
    return {
        conversationId: done.conversationId,
        status: done.status,
        answer: done.answer?.content ?? '',
        reasoning: done.answer?.reasoningContent ?? '',
    };
}
// ── Param Builders ────────────────────────────────────────────────────────────
function buildImageTaskParams(args) {
    const taskType = args.taskType;
    return {
        taskType,
        ...(args.positivePrompt !== undefined ? { positivePrompt: args.positivePrompt } : {}),
        ...(args.negativePrompt !== undefined ? { negativePrompt: args.negativePrompt } : {}),
        ...(args.aspectRatio !== undefined ? { aspectRatio: args.aspectRatio } : {}),
        ...(args.width !== undefined ? { width: args.width } : {}),
        ...(args.height !== undefined ? { height: args.height } : {}),
        ...(args.artSpecIds !== undefined ? { artSpecIds: args.artSpecIds } : {}),
        ...(args.referenceImages !== undefined ? { referenceImages: args.referenceImages } : {}),
        ...(args.outpaintSize !== undefined ? { outpaintSize: args.outpaintSize } : {}),
        ...(args.outfitControl !== undefined ? { outfitControl: args.outfitControl } : {}),
    };
}
function buildVideoTaskParams(args) {
    const taskType = args.taskType;
    return {
        taskType,
        // MCP exposes "positivePrompt" but the video API uses "prompt"
        ...(args.positivePrompt !== undefined ? { prompt: args.positivePrompt } : {}),
        ...(args.referenceResources !== undefined ? { referenceResources: args.referenceResources } : {}),
        ...(args.duration !== undefined ? { duration: args.duration } : {}),
        ...(args.aspectRatio !== undefined ? { aspectRatio: args.aspectRatio } : {}),
        ...(args.inferenceMode !== undefined ? { inferenceMode: args.inferenceMode } : {}),
        ...(args.enableSound !== undefined ? { enableSound: args.enableSound } : {}),
        ...(args.bodyProportionType !== undefined ? { bodyProportionType: args.bodyProportionType } : {}),
        ...(args.superResolveMode !== undefined ? { superResolveMode: args.superResolveMode } : {}),
        ...(args.parentTaskId !== undefined ? { parentTaskId: args.parentTaskId } : {}),
        ...(args.parentTaskType !== undefined ? { parentTaskType: args.parentTaskType } : {}),
        ...(args.originArtifactId !== undefined ? { originArtifactId: args.originArtifactId } : {}),
    };
}
// ── Formatters ────────────────────────────────────────────────────────────────
function formatImageTask(task) {
    return {
        taskId: task.taskId,
        taskType: task.taskType,
        status: task.status,
        artifacts: (task.artifacts ?? []).map((a) => ({
            resourceId: a.resourceId,
            resourceURL: a.resourceURL,
            thumbnailURL: a.thumbnailURL,
            width: a.width,
            height: a.height,
        })),
    };
}
function formatVideoTask(task) {
    return {
        taskId: task.id,
        taskType: task.taskType,
        status: task.status,
        artifacts: (task.artifacts ?? []).map((a) => ({
            resourceId: a.resourceId,
            resourceURL: a.resourceURL,
            thumbnailURL: a.thumbnailURL,
            videoResourceId: a.videoResource?.resourceId,
            videoResourceURL: a.videoResource?.resourceURL,
        })),
    };
}
// ── Dispatch ──────────────────────────────────────────────────────────────────
async function dispatch(name, args) {
    switch (name) {
        case 'upload_file': return handleUploadFile(args);
        case 'list_art_styles': return handleListArtStyles(args);
        case 'list_art_specs': return handleListArtSpecs(args);
        case 'create_image_task': return handleCreateImageTask(args);
        case 'check_image_task': return handleCheckImageTask(args);
        case 'list_image_tasks': return handleListImageTasks(args);
        case 'create_video_task': return handleCreateVideoTask(args);
        case 'check_video_task': return handleCheckVideoTask(args);
        case 'list_video_tasks': return handleListVideoTasks(args);
        case 'create_3d_project': return handleCreate3DProject(args);
        case 'check_3d_project': return handleCheck3DProject(args);
        case 'chat': return handleChat(args);
        default: throw new Error(`Unknown tool: ${name}`);
    }
}
// ── Server Setup ──────────────────────────────────────────────────────────────
const server = new Server({ name: 'aiart-mcp', version: '1.0.0' }, { capabilities: { tools: {} } });
server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args = {} } = request.params;
    try {
        const result = await dispatch(name, args);
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        return { content: [{ type: 'text', text: `Error: ${msg}` }], isError: true };
    }
});
const transport = new StdioServerTransport();
await server.connect(transport);
process.stderr.write(`AIART MCP server running (workspace: ${workspaceId})\n`);
//# sourceMappingURL=server.js.map