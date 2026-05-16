import type { StsCredentials, FileType } from './types.js';
export declare function uploadToOSS(sts: StsCredentials, fileBuffer: Buffer, mimeType?: string): Promise<string>;
export declare function getMimeType(filePath: string, fileType: FileType): string;
export declare function readFileBuffer(filePath: string): Buffer;
