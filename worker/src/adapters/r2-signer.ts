import { AwsClient } from 'aws4fetch';
import type { UrlSigner } from '../ports';

export interface R2Credentials {
  accountId: string;
  bucket: string;
  accessKeyId: string;
  secretAccessKey: string;
}

const PUT_EXPIRY_SECONDS = 15 * 60;
/** Long enough for a 500 MB video over a slow mobile connection. */
const PART_EXPIRY_SECONDS = 6 * 60 * 60;

/** Presigns S3-compatible URLs so browsers upload straight to R2, bypassing the Worker body limit. */
export class R2UrlSigner implements UrlSigner {
  private readonly client: AwsClient;
  private readonly endpoint: string;

  constructor(credentials: R2Credentials) {
    this.client = new AwsClient({
      accessKeyId: credentials.accessKeyId,
      secretAccessKey: credentials.secretAccessKey,
      service: 's3',
      region: 'auto',
    });
    this.endpoint = `https://${credentials.accountId}.r2.cloudflarestorage.com/${credentials.bucket}`;
  }

  async signPut(objectKey: string, mime: string): Promise<string> {
    const url = new URL(`${this.endpoint}/${objectKey}`);
    url.searchParams.set('X-Amz-Expires', String(PUT_EXPIRY_SECONDS));
    // Signing content-type means R2 rejects an upload that lies about its type.
    return this.sign(url, { 'content-type': mime });
  }

  async signPart(
    objectKey: string,
    multipartUploadId: string,
    partNumber: number,
  ): Promise<string> {
    const url = new URL(`${this.endpoint}/${objectKey}`);
    url.searchParams.set('partNumber', String(partNumber));
    url.searchParams.set('uploadId', multipartUploadId);
    url.searchParams.set('X-Amz-Expires', String(PART_EXPIRY_SECONDS));
    return this.sign(url, {});
  }

  private async sign(url: URL, headers: Record<string, string>): Promise<string> {
    const signed = await this.client.sign(new Request(url, { method: 'PUT', headers }), {
      aws: { signQuery: true, allHeaders: true },
    });
    return signed.url;
  }
}
