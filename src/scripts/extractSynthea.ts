import { createReadStream } from 'fs';
import { mkdir } from 'fs/promises';
import { join } from 'path';
import { Extract } from 'unzip-stream';

export async function extractSyntheaData(zipFiles: string[]): Promise<string> {
  const extractDir = join(process.cwd(), 'data', 'extracted');
  await mkdir(extractDir, { recursive: true });

  for (const zipFile of zipFiles) {
    await new Promise((resolve, reject) => {
      createReadStream(zipFile)
        .pipe(Extract({ path: extractDir }))
        .on('close', resolve)
        .on('error', reject);
    });
  }

  return extractDir;
}