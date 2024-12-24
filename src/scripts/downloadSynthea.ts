import { createWriteStream } from 'fs';
import { mkdir } from 'fs/promises';
import { join } from 'path';
import { get } from 'https';

const SYNTHEA_BASE_URL = 'https://synthetichealth.github.io/synthea-sample-data/downloads';
const SAMPLE_FILES = [
  'synthea_sample_data_fhir_r4_sep2019.zip',
  'synthea_sample_data_fhir_r4_may2020.zip'
];

async function downloadFile(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const file = createWriteStream(destPath);
    get(url, (response) => {
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', reject);
  });
}

export async function downloadSyntheaData(): Promise<string[]> {
  const dataDir = join(process.cwd(), 'data');
  await mkdir(dataDir, { recursive: true });

  const downloadedFiles: string[] = [];
  
  for (const file of SAMPLE_FILES) {
    const url = `${SYNTHEA_BASE_URL}/${file}`;
    const destPath = join(dataDir, file);
    
    console.log(`Downloading ${file}...`);
    await downloadFile(url, destPath);
    downloadedFiles.push(destPath);
    console.log(`Downloaded ${file}`);
  }

  return downloadedFiles;
}