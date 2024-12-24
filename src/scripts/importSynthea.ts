import { downloadSyntheaData } from './downloadSynthea';
import { extractSyntheaData } from './extractSynthea';
import { processSyntheaData } from './processSynthea';

async function main() {
  try {
    console.log('Starting Synthea data import...');
    
    console.log('Downloading Synthea data...');
    const zipFiles = await downloadSyntheaData();
    
    console.log('Extracting Synthea data...');
    const extractDir = await extractSyntheaData(zipFiles);
    
    console.log('Processing and importing patients...');
    const totalPatients = await processSyntheaData(extractDir);
    
    console.log(`Successfully imported ${totalPatients} patients!`);
  } catch (error) {
    console.error('Error importing Synthea data:', error);
    process.exit(1);
  }
}

main();