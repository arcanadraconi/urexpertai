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

async function testOrgSignup() {
  try {
    // Create organization admin
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: 'test@example.com',
      password: 'password123',
      options: {
        data: {
          organizationName: 'Test Organization'
        }
      }
    });

    if (authError) throw authError;
    console.log('User created:', authData);

    // Check profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*, organization:organizations(*), branch:branches(*)')
      .eq('id', authData.user?.id)
      .single();

    if (profileError) throw profileError;
    console.log('Profile created:', profile);

  } catch (error) {
    console.error('Error:', error);
  }
}

testOrgSignup();
