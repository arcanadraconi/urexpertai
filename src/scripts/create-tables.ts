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
  env.VITE_SUPABASE_SERVICE_ROLE_KEY
);

async function createTables() {
  try {
    // Create organizations table
    console.log('Creating organizations table...');
    const { error: orgError } = await supabase.rpc('create_organizations_table');
    if (orgError) {
      console.error('Error creating organizations table:', orgError);
      return;
    }

    // Create branches table
    console.log('Creating branches table...');
    const { error: branchError } = await supabase.rpc('create_branches_table');
    if (branchError) {
      console.error('Error creating branches table:', branchError);
      return;
    }

    // Update profiles table
    console.log('Updating profiles table...');
    const { error: profileError } = await supabase.rpc('update_profiles_table');
    if (profileError) {
      console.error('Error updating profiles table:', profileError);
      return;
    }

    console.log('Tables created successfully');

  } catch (error) {
    console.error('Error:', error);
  }
}

createTables();
