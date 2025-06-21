import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';

// Get the directory path of the current file
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables from .env file
const envPath = join(__dirname, '../../.env');
const envContent = readFileSync(envPath, 'utf-8');
const env = dotenv.parse(envContent);

const supabase = createClient(
  env.VITE_SUPABASE_URL,
  env.VITE_SUPABASE_ANON_KEY,
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true
    }
  }
);

async function checkSchema() {
  console.log('Checking organizations table schema...');
  
  try {
    // Try to insert a test record with name
    const { data, error } = await supabase
      .from('organizations')
      .insert([{
        name: 'Test Organization',
        code: 'ABCD1234EFGH5678' // 16 characters as per schema
      }])
      .select();

    if (error) {
      console.log('Error message (showing required columns):', error.message);
    } else {
      console.log('Table exists and record inserted:', data);
    }

    // Also try to select to see column names from the response
    const { data: existingData, error: selectError } = await supabase
      .from('organizations')
      .select()
      .limit(1);

    if (selectError) {
      console.error('Select error:', selectError.message);
    } else {
      console.log('Existing records:', existingData);
      if (existingData && existingData.length > 0) {
        console.log('Columns:', Object.keys(existingData[0]));
      }
    }

  } catch (error) {
    console.error('Error:', error);
  }
}

checkSchema();
