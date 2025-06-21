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

async function checkTables() {
  console.log('Checking tables...');
  
  try {
    // Try to select from organizations table
    const { data: orgs, error: orgsError } = await supabase
      .from('organizations')
      .select('*')
      .limit(1);

    if (orgsError) {
      console.error('Organizations table error:', orgsError.message);
    } else {
      console.log('Organizations table exists:', orgs);
    }

    // Try to select from profiles table
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('*')
      .limit(1);

    if (profilesError) {
      console.error('Profiles table error:', profilesError.message);
    } else {
      console.log('Profiles table exists:', profiles);
    }

  } catch (error) {
    console.error('Error:', error);
  }
}

checkTables();
