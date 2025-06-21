-- Migration Bundle 1

-- 0003_mellow_desert.sql
/*
  # Add contact information to patients table

  1. Changes
    - Add gender column to patients table
    - Add contact_info JSONB column to store:
      - address
      - phone
      - email

  2. Security
    - Maintain existing RLS policies
*/

DO $$ 
BEGIN
  -- Add gender column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'patients' AND column_name = 'gender'
  ) THEN
    ALTER TABLE patients ADD COLUMN gender TEXT;
  END IF;

  -- Add contact_info column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'patients' AND column_name = 'contact_info'
  ) THEN
    ALTER TABLE patients ADD COLUMN contact_info JSONB DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- 0004_steep_cliff.sql
/*
  # Organization RLS Policies
  
  1. New Policies
    - Allow organization creation during signup
    - Allow organization admins to manage their organizations
    - Allow users to view their organization
  
  2. Security
    - Enable RLS on organizations table
    - Add policies for create, read, update operations
*/

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow organization creation during signup" ON organizations;
DROP POLICY IF EXISTS "Allow organization admins to manage their organizations" ON organizations;
DROP POLICY IF EXISTS "Allow users to view their organization" ON organizations;

-- Create new policies
CREATE POLICY "Allow organization creation during signup"
ON organizations FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow organization admins to manage their organizations"
ON organizations FOR UPDATE
USING (admin_id = auth.uid())
WITH CHECK (admin_id = auth.uid());

CREATE POLICY "Allow users to view their organization"
ON organizations FOR SELECT
USING (
  id IN (
    SELECT organization_id 
    FROM profiles 
    WHERE id = auth.uid()
  )
  OR 
  admin_id = auth.uid()
);

-- 0005_tender_swamp.sql
/*
  # Update organization code format constraint

  1. Changes
    - Update the code format constraint to allow XXXX-XXXX-XXXX-XXXX format
    - Code can contain uppercase letters and numbers
*/

ALTER TABLE organizations 
  DROP CONSTRAINT IF EXISTS organizations_code_check;

ALTER TABLE organizations 
  ADD CONSTRAINT organizations_code_check 
  CHECK (code ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');

-- 0006_solitary_scene.sql
/*
  # Add Profile Creation Trigger

  1. Changes
    - Add function to handle profile creation on user signup
    - Add trigger to automatically create profiles for new users
    - Set default role as 'clinician' for users without organization

  2. Security
    - Function is set to SECURITY DEFINER to run with elevated privileges
    - Function is owned by postgres to ensure it can always create profiles
*/

-- Create the function that will handle profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- 0008_divine_pebble.sql
/*
  # Fix Organization Code Signup Process

  1. Changes
    - Add function to verify organization code and get organization ID
    - Update profile trigger to handle organization assignment
    - Add policy for organization code verification

  2. Security
    - Ensure proper access control for organization code verification
    - Maintain RLS policies
*/

-- Function to verify organization code and get organization ID
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  SELECT id INTO org_id
  FROM organizations
  WHERE code = code_to_verify;
  
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Invalid organization code';
  END IF;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the profile creation trigger to handle organization assignment
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Try to get organization ID if code is provided
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');
  END IF;

  INSERT INTO public.profiles (
    id,
    email,
    role,
    organization_id,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    CASE 
      WHEN org_id IS NOT NULL THEN 'clinician'
      WHEN NEW.raw_user_meta_data->>'role' IS NOT NULL THEN NEW.raw_user_meta_data->>'role'
      ELSE 'clinician'
    END,
    org_id,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add policy for organization code verification
CREATE POLICY "Allow organization code verification"
  ON organizations FOR SELECT
  USING (true);

-- 0009_delicate_hall.sql
/*
  # Fix Organization Code Verification

  1. Changes
    - Update organization code verification function
    - Add proper error handling
    - Ensure proper access control
*/

-- Drop existing function and recreate with better error handling
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Validate code format first
  IF NOT (code_to_verify ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') THEN
    RAISE EXCEPTION 'Invalid organization code format';
  END IF;

  -- Try to find organization
  SELECT id INTO org_id
  FROM organizations
  WHERE code = code_to_verify;
  
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Organization not found with the provided code';
  END IF;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Try to get organization ID if code is provided
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to verify organization code: %', SQLERRM;
    END;
  END IF;

  INSERT INTO public.profiles (
    id,
    email,
    role,
    organization_id,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
    org_id,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update organization policies to ensure proper access
DROP POLICY IF EXISTS "Allow organization code verification" ON organizations;

CREATE POLICY "Allow public organization code verification"
  ON organizations FOR SELECT
  USING (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- 0010_patient_manor.sql
/*
  # Fix Organization and Employee Signup

  1. Changes
    - Update profile creation trigger to handle organization admins
    - Update profile creation trigger to handle employees with organization codes
    - Add branch handling logic
    - Set proper roles
*/

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  branch_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Get the organization name
    org_name := NEW.raw_user_meta_data->>'organizationName';
    
    -- Create organization
    INSERT INTO organizations (name, admin_id, code)
    VALUES (org_name, NEW.id, generate_org_code())
    RETURNING id INTO org_id;

    -- Create default branch (same as organization)
    INSERT INTO branches (organization_id, name, location)
    VALUES (org_id, org_name, 'Main Branch')
    RETURNING id INTO branch_id;

    -- Create admin profile
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      branch_id,
      full_name,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'admin',
      org_id,
      branch_id,
      org_name,
      NOW(),
      NOW()
    );

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id, name INTO org_id, org_name
    FROM organizations
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Get the first branch ID (or create one if none exists)
    SELECT id INTO branch_id
    FROM branches
    WHERE organization_id = org_id
    LIMIT 1;

    IF branch_id IS NULL THEN
      INSERT INTO branches (organization_id, name, location)
      VALUES (org_id, org_name, 'Main Branch')
      RETURNING id INTO branch_id;
    END IF;

    -- Create employee profile
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      branch_id,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'nurse', -- Default role for employees
      org_id,
      branch_id,
      NOW(),
      NOW()
    );

  -- Handle regular user signup
  ELSE
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
      COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 0011_nameless_band.sql
/*
  # Update User Profile Creation Logic
  
  1. Changes
    - Drop trigger before function
    - Update function to handle organization signup
    - Add better error handling
    - Fix organization code verification
*/

-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Now we can safely drop and recreate the functions
DROP FUNCTION IF EXISTS verify_organization_code(text);
DROP FUNCTION IF EXISTS handle_new_user();

-- Create function to verify organization codes
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Validate code format
  IF NOT (code_to_verify ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') THEN
    RAISE EXCEPTION 'Invalid organization code format';
  END IF;

  -- Find organization
  SELECT id INTO org_id
  FROM organizations
  WHERE code = code_to_verify;
  
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Organization not found with the provided code';
  END IF;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the profile creation trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  branch_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- Create organization with generated code
      INSERT INTO organizations (name, admin_id, code)
      VALUES (
        NEW.raw_user_meta_data->>'organizationName',
        NEW.id,
        generate_org_code()
      )
      RETURNING id, name INTO org_id, org_name;

      -- Create default branch
      INSERT INTO branches (organization_id, name, location)
      VALUES (org_id, org_name, 'Main Branch')
      RETURNING id INTO branch_id;

      -- Create admin profile
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,
        branch_id,
        full_name,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'admin',
        org_id,
        branch_id,
        org_name,
        NOW(),
        NOW()
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create organization: %', SQLERRM;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- Get organization details
      SELECT id, name INTO org_id, org_name
      FROM organizations
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

      -- Get or create branch
      SELECT id INTO branch_id
      FROM branches
      WHERE organization_id = org_id
      LIMIT 1;

      IF branch_id IS NULL THEN
        INSERT INTO branches (organization_id, name, location)
        VALUES (org_id, org_name, 'Main Branch')
        RETURNING id INTO branch_id;
      END IF;

      -- Create employee profile
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,
        branch_id,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'nurse',
        org_id,
        branch_id,
        NOW(),
        NOW()
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to process organization code: %', SQLERRM;
    END;

  -- Handle regular user signup
  ELSE
    BEGIN
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
        COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
        NOW(),
        NOW()
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create user profile: %', SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code verification" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;

-- Policy for organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations 
  FOR SELECT
  USING (true);

-- Policy for organization creation
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL AND
    admin_id = auth.uid()
  );

-- 0012_calm_shrine.sql
/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Simplify organization code handling
    - Fix profile creation for both org admins and employees
    - Add proper error handling
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization with generated code
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
    RETURNING id, name INTO org_id, org_name;

    -- Create admin profile with organization name as full name
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      full_name,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'admin',
      org_id,
      org_name,
      NOW(),
      NOW()
    );

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id INTO org_id
    FROM organizations 
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Create employee profile
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'nurse',
      org_id,
      NOW(),
      NOW()
    );

  -- Handle regular user signup
  ELSE
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
      'clinician',
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 0013_tender_fountain.sql
/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Update trigger function to handle organization signup
    - Add proper error handling
    - Fix policy conflicts
*/

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization with generated code
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
    RETURNING id, name INTO org_id, org_name;

    -- Create admin profile with organization name as full name
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      full_name,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'admin',
      org_id,
      org_name,
      NOW(),
      NOW()
    );

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id INTO org_id
    FROM organizations 
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Create employee profile
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'nurse',
      org_id,
      NOW(),
      NOW()
    );

  -- Handle regular user signup
  ELSE
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
      'clinician',
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Create new policy for organization code verification
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'organizations' 
    AND policyname = 'Allow organization code lookup'
  ) THEN
    CREATE POLICY "Allow organization code lookup"
      ON organizations 
      FOR SELECT
      USING (true);
  END IF;
END $$;
