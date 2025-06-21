import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
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

async function createProcedures() {
  try {
    // Create organizations table procedure
    console.log('Creating create_organizations_table procedure...');
    const { error: orgProcError } = await supabase.rpc('create_procedure', {
      name: 'create_organizations_table',
      definition: `
        CREATE TABLE IF NOT EXISTS organizations (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name TEXT NOT NULL,
          admin_id UUID REFERENCES auth.users(id) NOT NULL,
          code TEXT UNIQUE NOT NULL,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );

        ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "Organization admins can manage their organization"
          ON organizations FOR ALL
          USING (admin_id = auth.uid());

        CREATE POLICY "Users can view their organization"
          ON organizations FOR SELECT
          USING (
            id IN (
              SELECT organization_id FROM profiles
              WHERE id = auth.uid()
            )
          );

        CREATE INDEX IF NOT EXISTS idx_organizations_admin_id ON organizations(admin_id);
        CREATE INDEX IF NOT EXISTS idx_organizations_code ON organizations(code);
      `
    });
    if (orgProcError) {
      console.error('Error creating organizations table procedure:', orgProcError);
      return;
    }

    // Create branches table procedure
    console.log('Creating create_branches_table procedure...');
    const { error: branchProcError } = await supabase.rpc('create_procedure', {
      name: 'create_branches_table',
      definition: `
        CREATE TABLE IF NOT EXISTS branches (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          organization_id UUID REFERENCES organizations(id) NOT NULL,
          name TEXT NOT NULL,
          location TEXT,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );

        ALTER TABLE branches ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "Organization admins can manage branches"
          ON branches FOR ALL
          USING (
            organization_id IN (
              SELECT id FROM organizations
              WHERE admin_id = auth.uid()
            )
          );

        CREATE POLICY "Users can view their branch"
          ON branches FOR SELECT
          USING (
            id IN (
              SELECT branch_id FROM profiles
              WHERE id = auth.uid()
            )
          );

        CREATE INDEX IF NOT EXISTS idx_branches_organization_id ON branches(organization_id);
      `
    });
    if (branchProcError) {
      console.error('Error creating branches table procedure:', branchProcError);
      return;
    }

    // Create update profiles table procedure
    console.log('Creating update_profiles_table procedure...');
    const { error: profileProcError } = await supabase.rpc('create_procedure', {
      name: 'update_profiles_table',
      definition: `
        ALTER TABLE profiles 
          ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id),
          ADD COLUMN IF NOT EXISTS branch_id UUID,
          DROP CONSTRAINT IF EXISTS profiles_role_check,
          ADD CONSTRAINT profiles_role_check 
            CHECK (role IN ('admin', 'reviewer', 'provider', 'nurse'));

        CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON profiles(organization_id);
      `
    });
    if (profileProcError) {
      console.error('Error creating update profiles table procedure:', profileProcError);
      return;
    }

    // Create generate_org_code function
    console.log('Creating generate_org_code function...');
    const { error: codeError } = await supabase.rpc('create_function', {
      name: 'generate_org_code',
      definition: `
        CREATE OR REPLACE FUNCTION generate_org_code()
        RETURNS TEXT AS $$
        DECLARE
          chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
          result TEXT := '';
          part TEXT;
          i INTEGER := 0;
          success BOOLEAN := false;
          max_attempts INTEGER := 10;
          attempt INTEGER := 0;
        BEGIN
          WHILE NOT success AND attempt < max_attempts LOOP
            result := '';
            FOR i IN 1..4 LOOP
              part := '';
              FOR j IN 1..4 LOOP
                part := part || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
              END LOOP;
              
              IF i < 4 THEN
                result := result || part || '-';
              ELSE
                result := result || part;
              END IF;
            END LOOP;
            
            IF NOT EXISTS (SELECT 1 FROM organizations WHERE code = result) THEN
              success := true;
            END IF;
            
            attempt := attempt + 1;
          END LOOP;
          
          IF NOT success THEN
            RAISE EXCEPTION 'Could not generate unique organization code after % attempts', max_attempts;
          END IF;
          
          RETURN result;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
      `
    });
    if (codeError) {
      console.error('Error creating generate_org_code function:', codeError);
      return;
    }

    // Create handle_new_user trigger function
    console.log('Creating handle_new_user trigger function...');
    const { error: triggerError } = await supabase.rpc('create_function', {
      name: 'handle_new_user',
      definition: `
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS trigger AS $$
        BEGIN
          -- Create basic profile first
          INSERT INTO public.profiles (
            id,
            email,
            role,
            created_at,
            updated_at
          )
          VALUES (
            NEW.id,
            NEW.email,
            CASE 
              WHEN NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN 'admin'
              WHEN NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN 'nurse'
              ELSE 'admin'
            END,
            NOW(),
            NOW()
          );

          -- If this is an organization admin signup
          IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
            WITH new_org AS (
              INSERT INTO organizations (
                name,
                admin_id,
                code
              )
              VALUES (
                NEW.raw_user_meta_data->>'organizationName',
                NEW.id,
                generate_org_code()
              )
              RETURNING id
            ),
            new_branch AS (
              INSERT INTO branches (
                organization_id,
                name,
                location
              )
              SELECT 
                id,
                'Main Branch',
                'Default Location'
              FROM new_org
              RETURNING id, organization_id
            )
            UPDATE public.profiles
            SET 
              organization_id = new_branch.organization_id,
              branch_id = new_branch.id
            FROM new_branch
            WHERE profiles.id = NEW.id;
          
          -- If this is an employee signup with organization code
          ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
            WITH org_info AS (
              SELECT o.id as org_id, b.id as branch_id
              FROM organizations o
              LEFT JOIN branches b ON b.organization_id = o.id
              WHERE o.code = NEW.raw_user_meta_data->>'organization_code'
              LIMIT 1
            )
            UPDATE public.profiles
            SET 
              organization_id = org_info.org_id,
              branch_id = org_info.branch_id
            FROM org_info
            WHERE profiles.id = NEW.id;
          END IF;

          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;

        -- Create trigger
        DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
        CREATE TRIGGER on_auth_user_created
          AFTER INSERT ON auth.users
          FOR EACH ROW
          EXECUTE FUNCTION public.handle_new_user();

        -- Set permissions
        ALTER FUNCTION public.handle_new_user() OWNER TO postgres;
        ALTER FUNCTION generate_org_code() OWNER TO postgres;
      `
    });
    if (triggerError) {
      console.error('Error creating handle_new_user trigger function:', triggerError);
      return;
    }

    console.log('All procedures created successfully');

  } catch (error) {
    console.error('Error:', error);
  }
}

createProcedures();
