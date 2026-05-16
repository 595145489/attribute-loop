import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
// Returns the ETag of the uploaded object (quotes stripped).
export async function uploadToOSS(sts, fileBuffer, mimeType) {
    if (sts.provider !== 'aliyun') {
        throw new Error(`Unsupported storage provider: ${sts.provider}`);
    }
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const OSSClient = (await import('ali-oss')).default;
    const hostStr = sts.host.startsWith('http') ? sts.host : `https://${sts.host}`;
    const hostUrl = new URL(hostStr);
    const parts = hostUrl.hostname.split('.');
    const bucket = parts[0];
    const region = parts[1]; // e.g. 'oss-cn-hangzhou'
    const client = new OSSClient({
        region,
        bucket,
        accessKeyId: sts.accessKeyId,
        accessKeySecret: sts.accessKeySecret,
        stsToken: sts.securityToken,
    });
    const dir = sts.targetDir.endsWith('/') ? sts.targetDir : `${sts.targetDir}/`;
    const objectKey = dir + sts.targetFilename;
    const result = await client.put(objectKey, fileBuffer, mimeType ? { mime: mimeType } : undefined);
    // OSS returns ETag as '"UPPERCASE_MD5"' (with surrounding quotes in the header value).
    // The register endpoint expects the ETag including those quotes.
    const headers = result.res?.headers ?? {};
    const rawEtag = headers.etag ?? headers.ETag ?? '';
    if (rawEtag)
        return rawEtag;
    // Fallback: reproduce OSS ETag format
    return `"${crypto.createHash('md5').update(fileBuffer).digest('hex').toUpperCase()}"`;
}
export function getMimeType(filePath, fileType) {
    const ext = path.extname(filePath).toLowerCase();
    const map = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.bmp': 'image/bmp',
        '.mp4': 'video/mp4',
        '.mov': 'video/quicktime',
        '.avi': 'video/x-msvideo',
        '.webm': 'video/webm',
        '.mp3': 'audio/mpeg',
        '.wav': 'audio/wav',
        '.m4a': 'audio/mp4',
        '.aac': 'audio/aac',
    };
    return map[ext] ?? `${fileType}/*`;
}
export function readFileBuffer(filePath) {
    if (!fs.existsSync(filePath)) {
        throw new Error(`File not found: ${filePath}`);
    }
    return fs.readFileSync(filePath);
}
//# sourceMappingURL=upload.js.map