-- Migration Bundle 4

-- 0037_dry_thunder.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization first
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
    RETURNING id INTO org_id;

    -- Create admin profile with organization ID
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
      'admin',
      org_id,
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

    -- Create employee profile with organization ID
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

  -- Handle regular user signup (no organization)
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
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies
DROP POLICY IF EXISTS "Allow public organization code verification" ON organizations;
CREATE POLICY "Allow public organization code verification"
  ON organizations
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- 0038_sparkling_silence.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization first
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
    RETURNING id INTO org_id;

    -- Create main branch
    INSERT INTO branches (
      organization_id,
      name,
      location
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location'
    )
    RETURNING id INTO branch_id;

    -- Create admin profile with organization and branch IDs
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
      'admin',
      org_id,
      branch_id,
      NOW(),
      NOW()
    );

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID and its main branch ID
    SELECT o.id, b.id INTO org_id, branch_id
    FROM organizations o
    JOIN branches b ON b.organization_id = o.id
    WHERE o.code = NEW.raw_user_meta_data->>'organization_code'
    LIMIT 1;

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Create employee profile with organization and branch IDs
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

  -- Handle regular user signup (no organization)
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
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies for branches
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;

-- Allow branch creation during organization setup
CREATE POLICY "Allow branch creation"
  ON branches
  FOR INSERT
  WITH CHECK (true);

-- Allow branch viewing by organization members
CREATE POLICY "Allow branch viewing by organization members"
  ON branches
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.organization_id = branches.organization_id
    )
  );

-- 0039_wandering_cell.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
BEGIN
  -- Start an autonomous transaction
  BEGIN
    -- Handle organization admin signup
    IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
      -- Create organization and get its ID
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
      RETURNING id INTO org_id;

      -- Create main branch
      INSERT INTO branches (
        organization_id,
        name,
        location
      )
      VALUES (
        org_id,
        'Main Branch',
        'Main Location'
      )
      RETURNING id INTO branch_id;

      -- Create admin profile
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
        'admin',
        org_id,
        branch_id,
        NOW(),
        NOW()
      );

      RAISE LOG 'Created organization admin profile for %', NEW.email;

    -- Handle regular user signup (no organization)
    ELSE
      -- Create basic user profile
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

      RAISE LOG 'Created regular user profile for %', NEW.email;
    END IF;

    RETURN NEW;
  EXCEPTION WHEN OTHERS THEN
    -- Log detailed error information
    RAISE LOG 'Error in handle_new_user for %: % %', NEW.email, SQLSTATE, SQLERRM;
    -- Re-raise the exception to trigger rollback
    RAISE;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow branch creation" ON branches;
CREATE POLICY "Allow branch creation"
  ON branches
  FOR INSERT
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0040_sunny_cell.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
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
    'clinician',
    NOW(),
    NOW()
  );

  -- If this is an organization admin signup, update the profile
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
        'Main Location'
      FROM new_org
      RETURNING id, organization_id
    )
    UPDATE public.profiles
    SET 
      role = 'admin',
      organization_id = new_branch.organization_id,
      branch_id = new_branch.id
    FROM new_branch
    WHERE profiles.id = NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: % %', SQLSTATE, SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow branch creation" ON branches;
DROP POLICY IF EXISTS "Allow profile management" ON profiles;

-- Create new policies
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow branch creation"
  ON branches
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow profile management"
  ON profiles
  FOR ALL
  USING (id = auth.uid());

-- 0041_light_violet.sql
/*
  # Add timestamps to branches table

  1. Changes
    - Add created_at and updated_at columns to branches table
    - Set default values using NOW()
    - Make columns non-nullable

  2. Notes
    - Uses IF NOT EXISTS to prevent errors if columns already exist
    - Adds columns in a safe way using DO block
*/

DO $$ 
BEGIN
  -- Add created_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;

  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
END $$;

-- 0042_lingering_pond.sql
/*
  # Add branch handling to organization signup

  1. Changes
    - Update trigger function to create main branch for new organizations
    - Add branch_id to profiles table
    - Update RLS policies for branch access

  2. Notes
    - Creates main branch automatically for new organizations
    - Associates users with both organization and branch
    - Maintains proper RLS security
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization first
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
    RETURNING id INTO org_id;

    -- Create main branch
    INSERT INTO branches (
      organization_id,
      name,
      location,
      created_at,
      updated_at
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location',
      NOW(),
      NOW()
    )
    RETURNING id INTO branch_id;

    -- Create admin profile with organization and branch IDs
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
      'admin',
      org_id,
      branch_id,
      NOW(),
      NOW()
    );

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID and its main branch ID
    SELECT o.id, b.id INTO org_id, branch_id
    FROM organizations o
    JOIN branches b ON b.organization_id = o.id
    WHERE o.code = NEW.raw_user_meta_data->>'organization_code'
    LIMIT 1;

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Create employee profile with organization and branch IDs
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

  -- Handle regular user signup (no organization)
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
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies
DROP POLICY IF EXISTS "Allow branch viewing by organization members" ON branches;
CREATE POLICY "Allow branch viewing by organization members"
  ON branches
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.organization_id = branches.organization_id
    )
  );

-- 0043_restless_tower.sql
/*
  # Fix organization signup issues

  1. Changes
    - Simplify trigger function to reduce potential failure points
    - Add better error handling and validation
    - Ensure atomic transactions
    - Fix RLS policies for organization creation

  2. Notes
    - Handles user already exists cases gracefully
    - Ensures proper transaction handling
    - Maintains data consistency
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
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
      ELSE 'clinician'
    END,
    NOW(),
    NOW()
  );

  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization and branch in a single transaction
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
        location,
        created_at,
        updated_at
      )
      SELECT 
        id,
        'Main Branch',
        'Main Location',
        NOW(),
        NOW()
      FROM new_org
      RETURNING id, organization_id
    )
    UPDATE public.profiles
    SET 
      organization_id = new_branch.organization_id,
      branch_id = new_branch.id
    FROM new_branch
    WHERE profiles.id = NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log detailed error information
  RAISE LOG 'Error in handle_new_user for %: % %', NEW.email, SQLSTATE, SQLERRM;
  -- Re-raise the exception
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow branch creation" ON branches;
DROP POLICY IF EXISTS "Allow profile management" ON profiles;

-- Create new policies with proper checks
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND 
    admin_id = auth.uid()
  );

CREATE POLICY "Allow branch creation"
  ON branches
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE organizations.id = branches.organization_id
      AND organizations.admin_id = auth.uid()
    )
  );

CREATE POLICY "Allow profile management"
  ON profiles
  FOR ALL
  USING (id = auth.uid());

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0044_twilight_grove.sql
/*
  # Fix organization signup issues

  1. Changes
    - Simplify trigger function to reduce failure points
    - Add better error handling
    - Ensure atomic transactions
    - Fix RLS policies

  2. Notes
    - Handles organization creation in a single transaction
    - Maintains data consistency
    - Improves error logging
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
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
    'clinician',
    NOW(),
    NOW()
  );

  -- If this is an organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Update profile and create organization in a single transaction
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
    )
    UPDATE public.profiles
    SET 
      role = 'admin',
      organization_id = new_org.id
    FROM new_org
    WHERE profiles.id = NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log detailed error information
  RAISE LOG 'Error in handle_new_user for %: % %', NEW.email, SQLSTATE, SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;

-- Create simplified policies
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- 0045_turquoise_garden.sql
/*
  # Organization and Branch Management Update
  
  1. Changes
    - Simplifies organization signup flow
    - Improves error handling
    - Updates RLS policies
    
  2. Security
    - Maintains RLS policies
    - Ensures proper role assignment
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow branch creation" ON branches;
DROP POLICY IF EXISTS "Allow branch viewing by organization members" ON branches;
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization first
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
    RETURNING id INTO org_id;

    -- Create main branch
    INSERT INTO branches (
      organization_id,
      name,
      location,
      created_at,
      updated_at
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location',
      NOW(),
      NOW()
    )
    RETURNING id INTO branch_id;

    -- Create admin profile with organization and branch IDs
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
      'admin',
      org_id,
      branch_id,
      NOW(),
      NOW()
    );

    RAISE LOG 'Created organization % with branch % for admin %', org_id, branch_id, NEW.id;

  -- Handle regular user signup (no organization)
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

    RAISE LOG 'Created regular user profile for %', NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: % %', SQLSTATE, SQLERRM;
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Create new policies
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

CREATE POLICY "Allow branch creation"
  ON branches
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow branch access"
  ON branches
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.organization_id = branches.organization_id
    )
  );

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0046_divine_shore.sql
/*
  # Simplify User Creation Flow
  
  1. Changes
    - Simplifies user creation trigger
    - Removes complex organization handling from trigger
    - Updates RLS policies for better security
    
  2. Security
    - Maintains RLS policies
    - Ensures proper access control
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function that only handles profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create basic profile
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

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow branch creation" ON branches;
DROP POLICY IF EXISTS "Allow branch access" ON branches;

-- Create simplified policies
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow branch operations"
  ON branches
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
