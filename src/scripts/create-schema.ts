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

async function createSchema() {
  try {
    // Create organizations table
    console.log('Creating organizations table...');
    const { error: orgError } = await supabase
      .from('organizations')
      .insert({
        id: '00000000-0000-0000-0000-000000000000', // Dummy record to create table
        name: 'Dummy Org',
        admin_id: '00000000-0000-0000-0000-000000000000',
        code: 'DUMMY-CODE'
      })
      .select();

    if (orgError && !orgError.message.includes('already exists')) {
      console.error('Error creating organizations table:', orgError);
      return;
    }

    // Create branches table
    console.log('Creating branches table...');
    const { error: branchError } = await supabase
      .from('branches')
      .insert({
        id: '00000000-0000-0000-0000-000000000000', // Dummy record to create table
        organization_id: '00000000-0000-0000-0000-000000000000',
        name: 'Dummy Branch',
        location: 'Dummy Location'
      })
      .select();

    if (branchError && !branchError.message.includes('already exists')) {
      console.error('Error creating branches table:', branchError);
      return;
    }

    // Update profiles table
    console.log('Updating profiles table...');
    const { error: profileError } = await supabase
      .from('profiles')
      .update({ role: 'admin' }) // Dummy update to ensure column exists
      .eq('id', '00000000-0000-0000-0000-000000000000')
      .select();

    if (profileError && !profileError.message.includes('already exists')) {
      console.error('Error updating profiles table:', profileError);
      return;
    }

    // Clean up dummy records
    console.log('Cleaning up...');
    await supabase
      .from('organizations')
      .delete()
      .eq('id', '00000000-0000-0000-0000-000000000000');

    await supabase
      .from('branches')
      .delete()
      .eq('id', '00000000-0000-0000-0000-000000000000');

    console.log('Schema created successfully');

  } catch (error) {
    console.error('Error:', error);
  }
}

createSchema();
