import { readFile, readdir } from 'fs/promises';
import { join } from 'path';
import { FHIRPatient } from '../types/fhir.types';
import { importSyntheaPatients } from '../lib/synthea';

export async function processSyntheaData(extractDir: string): Promise<number> {
  const files = await readdir(extractDir);
  const patientFiles = files.filter(f => f.startsWith('Patient') && f.endsWith('.json'));

  let totalPatients = 0;
  
  for (const file of patientFiles) {
    const filePath = join(extractDir, file);
    const content = await readFile(filePath, 'utf-8');
    const patients = JSON.parse(content).entry.map((e: any) => e.resource as FHIRPatient);
    
    console.log(`Processing ${patients.length} patients from ${file}...`);
    totalPatients += await importSyntheaPatients(patients);
  }

  return totalPatients;
}