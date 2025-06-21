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
  env.VITE_SUPABASE_ANON_KEY
);

async function checkTrigger() {
  console.log('Checking trigger...');
  
  try {
    // Try to run the trigger function directly
    const { data, error } = await supabase.rpc('handle_new_user', {
      raw_user_meta_data: {
        organizationName: 'Test Organization'
      },
      id: '12345',
      email: 'test@example.com'
    });

    if (error) {
      console.error('Trigger function error:', error.message);
    } else {
      console.log('Trigger function exists:', data);
    }

  } catch (error) {
    console.error('Error:', error);
  }
}

checkTrigger();
