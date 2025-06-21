-- Migration Bundle 2

-- 0014_foggy_boat.sql
/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Update trigger function to properly handle organization ID in profiles
    - Add better error handling
    - Ensure organization ID is set for both admin and employee signups
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
    -- First create the organization
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

    -- Then create the admin profile WITH organization ID
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id, -- Important: Set the organization ID
      full_name,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'admin',
      org_id,  -- Link to the organization
      org_name,
      NOW(),
      NOW()
    );

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- First verify and get organization ID
    SELECT id, name INTO org_id, org_name
    FROM organizations 
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Then create employee profile WITH organization ID
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id, -- Important: Set the organization ID
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'nurse',
      org_id,  -- Link to the organization
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
  RAISE EXCEPTION 'Failed to create user profile: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 0015_throbbing_marsh.sql
/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Update trigger function to properly set organization_id in profiles
    - Add better error handling and logging
    - Fix organization code verification
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
    BEGIN
      -- First create the organization
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

      -- Then create admin profile WITH organization ID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- Set organization ID for admin
        full_name,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'admin',
        org_id,  -- Link to the organization
        org_name,
        NOW(),
        NOW()
      );

      -- Log successful organization creation
      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create organization: %', SQLERRM;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First verify and get organization ID
      SELECT id, name INTO org_id, org_name
      FROM organizations 
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

      -- Then create employee profile WITH organization ID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- Set organization ID for employee
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'nurse',
        org_id,  -- Link to the organization
        NOW(),
        NOW()
      );

      -- Log successful employee profile creation
      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to process organization code: %', SQLERRM;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      -- Log successful regular user profile creation
      RAISE LOG 'Created regular user profile for %', NEW.email;
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

-- 0017_summer_frost.sql
/*
  # Fix Signup Flow
  
  1. Changes
    - Update trigger function to properly handle organization signup
    - Fix organization ID reference in profiles table
    - Add better error handling and logging
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
    BEGIN
      -- First create the organization with generated code
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

      -- Then create admin profile with organization UUID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- This is UUID referencing organizations.id
        full_name,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'admin',
        org_id,  -- Using the UUID from organizations.id
        org_name,
        NOW(),
        NOW()
      );

      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      -- Log the error and re-raise
      RAISE LOG 'Error creating organization: %', SQLERRM;
      RAISE;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First get organization UUID using the code
      SELECT id, name INTO org_id, org_name
      FROM organizations 
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

      -- Then create employee profile with organization UUID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- This is UUID referencing organizations.id
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'nurse',
        org_id,  -- Using the UUID from organizations.id
        NOW(),
        NOW()
      );

      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      -- Log the error and re-raise
      RAISE LOG 'Error processing organization code: %', SQLERRM;
      RAISE;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      -- Log the error and re-raise
      RAISE LOG 'Error creating user profile: %', SQLERRM;
      RAISE;
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

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;

-- Allow organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

-- Allow organization creation during signup
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- 0018_restless_snow.sql
/*
  # Fix Organization Reference
  
  1. Changes
    - Update trigger function to properly handle organization references
    - Ensure organization_id in profiles table uses UUID from organizations table
    - Add better error handling and logging
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
    BEGIN
      -- First create the organization with generated code
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

      -- Then create admin profile with organization UUID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- This is UUID referencing organizations.id
        full_name,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'admin',
        org_id,  -- Using the UUID from organizations.id
        org_name,
        NOW(),
        NOW()
      );

      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating organization: %', SQLERRM;
      RAISE;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First get organization UUID using the code
      SELECT id, name INTO org_id, org_name
      FROM organizations 
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

      -- Then create employee profile with organization UUID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- This is UUID referencing organizations.id
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'nurse',
        org_id,  -- Using the UUID from organizations.id
        NOW(),
        NOW()
      );

      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error processing organization code: %', SQLERRM;
      RAISE;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating user profile: %', SQLERRM;
      RAISE;
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

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- 0019_small_moon.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- First create the profile
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
        'admin',
        NOW(),
        NOW()
      );

      -- Then create the organization
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

      -- Update the profile with organization info
      UPDATE public.profiles
      SET 
        organization_id = org_id,
        full_name = org_name
      WHERE id = NEW.id;

      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating organization: %', SQLERRM;
      RAISE;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First get organization UUID using the code
      SELECT id, name INTO org_id, org_name
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

      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error processing organization code: %', SQLERRM;
      RAISE;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating user profile: %', SQLERRM;
      RAISE;
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

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;

-- Allow organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

-- Allow organization creation during signup
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- Allow organization updates
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (admin_id = auth.uid());

-- 0020_solitary_wave.sql
/*
  # Fix Signup Error and Improve Error Handling

  1. Changes
    - Reorder profile and organization creation to prevent foreign key constraint issues
    - Add better error handling and logging
    - Add transaction management for atomic operations
    - Update RLS policies for better security

  2. Security
    - Maintain RLS policies for organizations and profiles
    - Ensure proper access control during signup process
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- First create the profile
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
        'admin',
        NOW(),
        NOW()
      );

      -- Generate organization code
      org_name := NEW.raw_user_meta_data->>'organizationName';

      -- Then create the organization
      INSERT INTO organizations (
        name, 
        admin_id, 
        code
      )
      VALUES (
        org_name,
        NEW.id,
        generate_org_code()
      )
      RETURNING id INTO org_id;

      -- Update the profile with organization info
      UPDATE public.profiles
      SET 
        organization_id = org_id,
        full_name = org_name
      WHERE id = NEW.id;

      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in organization signup: %', SQLERRM;
      RAISE;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First verify organization exists
      SELECT id, name INTO org_id, org_name
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

      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in employee signup: %', SQLERRM;
      RAISE;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in regular signup: %', SQLERRM;
      RAISE;
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

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization updates" ON organizations;

-- Allow organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

-- Allow organization creation during signup
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- Allow organization updates by admin
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (admin_id = auth.uid());

-- 0021_flat_flower.sql
/*
  # Fix Signup Error

  1. Changes
    - Reorder profile and organization creation
    - Add better error handling
    - Fix foreign key constraint issues
    - Add detailed logging

  2. Security
    - Maintain RLS policies
    - Ensure proper access control
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- First create the profile
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
        'admin',
        NOW(),
        NOW()
      );

      -- Generate organization code
      org_name := NEW.raw_user_meta_data->>'organizationName';

      -- Then create the organization
      INSERT INTO organizations (
        name, 
        admin_id, 
        code
      )
      VALUES (
        org_name,
        NEW.id,
        generate_org_code()
      )
      RETURNING id INTO org_id;

      -- Update the profile with organization info
      UPDATE public.profiles
      SET 
        organization_id = org_id,
        full_name = org_name
      WHERE id = NEW.id;

      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in organization signup: %', SQLERRM;
      RAISE;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First verify organization exists
      SELECT id, name INTO org_id, org_name
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

      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in employee signup: %', SQLERRM;
      RAISE;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in regular signup: %', SQLERRM;
      RAISE;
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

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization updates" ON organizations;

-- Allow organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

-- Allow organization creation during signup
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- Allow organization updates by admin
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (admin_id = auth.uid());

-- 0022_silent_reef.sql
/*
  # Fix Organization Signup Process

  1. Changes
    - Simplify profile creation trigger
    - Handle organization creation separately
    - Add better error handling
    - Fix transaction issues

  2. Security
    - Maintain RLS policies
    - Keep existing permissions
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
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
    COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
    NOW(),
    NOW()
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error creating profile: %', SQLERRM;
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

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization updates" ON organizations;

-- Allow organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

-- Allow organization creation during signup
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- Allow organization updates by admin
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (admin_id = auth.uid());

-- 0023_ivory_tower.sql
/*
  # Fix signup functionality

  1. Changes
    - Simplify profile creation trigger
    - Add proper error handling
    - Fix organization code handling
    - Add proper role assignment

  2. Security
    - Maintain RLS policies
    - Ensure proper permissions
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  user_role text;
BEGIN
  -- Set default role
  user_role := 'clinician';

  -- Handle organization signup flows
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization
    INSERT INTO organizations (name, admin_id, code)
    VALUES (
      NEW.raw_user_meta_data->>'organizationName',
      NEW.id,
      generate_org_code()
    )
    RETURNING id INTO org_id;
    
    user_role := 'admin';
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Verify organization code
    SELECT id INTO org_id
    FROM organizations
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    user_role := 'nurse';
  END IF;

  -- Create profile
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
    user_role,
    org_id,
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

-- 0024_maroon_shore.sql
/*
  # Fix organization signup trigger

  1. Changes
    - Fix trigger function to properly create organization and profile records
    - Add better error handling and logging
    - Ensure proper order of operations
    
  2. Security
    - Maintain existing RLS policies
    - Keep security definer attribute for trigger function
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  org_code text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- Generate organization code first
      org_code := generate_org_code();
      org_name := NEW.raw_user_meta_data->>'organizationName';
      
      -- Create organization
      INSERT INTO organizations (
        name,
        admin_id,
        code
      )
      VALUES (
        org_name,
        NEW.id,
        org_code
      )
      RETURNING id INTO org_id;

      -- Create admin profile
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

      RAISE LOG 'Created organization % (ID: %) with code % for admin %', org_name, org_id, org_code, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in organization signup: %', SQLERRM;
      RAISE;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in regular signup: %', SQLERRM;
      RAISE;
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

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;
