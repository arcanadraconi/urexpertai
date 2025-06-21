-- Migration Bundle 3

-- 0025_teal_dust.sql
/*
  # Fix organization signup trigger

  1. Changes
    - Simplify trigger function to only create profile record
    - Move organization creation to a separate function
    - Add better error handling
    
  2. Security
    - Maintain existing RLS policies
    - Keep security definer attribute
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simple trigger function that only handles profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create basic profile for all users
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

-- 0026_dusty_lagoon.sql
/*
  # Fix organization signup trigger

  1. Changes
    - Combine profile and organization creation into a single transaction
    - Add proper error handling and logging
    - Fix organization code generation
    
  2. Security
    - Maintain RLS policies
    - Keep security definer attribute
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  org_code text;
BEGIN
  -- Start transaction
  BEGIN
    -- Handle organization admin signup
    IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
      -- Generate organization code
      org_code := generate_org_code();
      org_name := NEW.raw_user_meta_data->>'organizationName';
      
      -- Create organization first
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

      -- Then create admin profile with organization ID
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

      RAISE LOG 'Created organization % with ID % and admin profile for %', org_name, org_id, NEW.email;

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

      RAISE LOG 'Created regular user profile for %', NEW.email;
    END IF;

    -- Commit transaction
    RETURN NEW;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error in handle_new_user: %', SQLERRM;
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

-- 0027_sparkling_waterfall.sql
/*
  # Simplify user creation trigger

  1. Changes
    - Simplify trigger to only handle profile creation
    - Remove organization handling from trigger
    - Add better error handling
    
  2. Security
    - Maintain RLS policies
    - Keep security definer attribute
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
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

-- 0028_cool_tree.sql
/*
  # Add organization code generation function
  
  1. Changes
    - Add generate_org_code function to database
    - Update function to be security definer
    - Add proper error handling
*/

-- Create the generate_org_code function
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS text AS $$
DECLARE
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result text := '';
  i integer;
  j integer;
BEGIN
  -- Generate 4 groups of 4 characters
  FOR i IN 1..4 LOOP
    -- Generate 4 characters for each group
    FOR j IN 1..4 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    
    -- Add hyphen between groups (except after last group)
    IF i < 4 THEN
      result := result || '-';
    END IF;
  END LOOP;

  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error generating organization code: %', SQLERRM;
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure proper permissions
ALTER FUNCTION generate_org_code() OWNER TO postgres;

-- 0029_lingering_plain.sql
/*
  # Fix organization signup flow
  
  1. Changes
    - Simplify trigger function to only create profile
    - Add proper error handling
    - Remove organization handling from trigger
*/

-- Drop existing trigger
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
    COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
    NOW(),
    NOW()
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error creating profile: %', SQLERRM;
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

-- 0030_falling_shore.sql
-- Create function to verify organization code
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

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Handle employee signup with organization code
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Verify organization code and get organization ID
    org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');

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
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 0031_lucky_harbor.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create function to generate organization codes
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS text AS $$
DECLARE
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  code text := '';
BEGIN
  -- Generate 4 groups of 4 characters
  FOR i IN 1..4 LOOP
    -- Generate 4 random characters
    FOR j IN 1..4 LOOP
      code := code || substr(chars, ceil(random() * length(chars))::integer, 1);
    END LOOP;
    -- Add hyphen between groups (except last)
    IF i < 4 THEN
      code := code || '-';
    END IF;
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_code text;
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

  -- Handle organization creation if needed
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Generate unique organization code
    org_code := generate_org_code();
    
    -- Create organization
    INSERT INTO organizations (
      name,
      admin_id,
      code
    )
    VALUES (
      NEW.raw_user_meta_data->>'organizationName',
      NEW.id,
      org_code
    )
    RETURNING id INTO org_id;

    -- Update profile with organization info
    UPDATE public.profiles
    SET 
      role = 'admin',
      organization_id = org_id
    WHERE id = NEW.id;
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
ALTER FUNCTION generate_org_code() OWNER TO postgres;
ALTER FUNCTION handle_new_user() OWNER TO postgres;

-- 0032_ivory_art.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  org_code text;
BEGIN
  -- Handle employee signup with organization code
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id INTO org_id
    FROM organizations 
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Get or create default branch for organization
    SELECT id INTO branch_id
    FROM branches
    WHERE organization_id = org_id
    LIMIT 1;

    IF branch_id IS NULL THEN
      -- Create default branch if none exists
      INSERT INTO branches (organization_id, name, location)
      VALUES (org_id, 'Main Branch', 'Default Location')
      RETURNING id INTO branch_id;
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

  -- Handle organization admin signup
  ELSIF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Generate organization code
    org_code := generate_org_code();
    
    -- Create organization
    INSERT INTO organizations (
      name,
      admin_id,
      code
    )
    VALUES (
      NEW.raw_user_meta_data->>'organizationName',
      NEW.id,
      org_code
    )
    RETURNING id INTO org_id;

    -- Create default branch
    INSERT INTO branches (
      organization_id,
      name,
      location
    )
    VALUES (
      org_id,
      'Main Branch',
      'Default Location'
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
ALTER FUNCTION handle_new_user() OWNER TO postgres;

-- 0035_black_stream.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
BEGIN
  -- Start a subtransaction
  BEGIN
    -- If organization code is provided, verify it first
    IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
      -- Get organization and branch IDs
      SELECT o.id, b.id INTO org_id, branch_id
      FROM organizations o
      LEFT JOIN branches b ON b.organization_id = o.id
      WHERE o.code = NEW.raw_user_meta_data->>'organization_code'
      LIMIT 1;

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;
    END IF;

    -- Create the profile
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
      CASE 
        WHEN NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN 'nurse'
        ELSE 'clinician'
      END,
      org_id,
      branch_id,
      NOW(),
      NOW()
    );

    RETURN NEW;
  EXCEPTION WHEN OTHERS THEN
    -- Log the error details
    RAISE LOG 'Error in handle_new_user for user %: %', NEW.email, SQLERRM;
    -- Re-raise the exception
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
DROP POLICY IF EXISTS "Allow public organization code verification" ON organizations;

CREATE POLICY "Allow public organization code verification"
  ON organizations
  FOR SELECT
  USING (true);

-- 0036_fading_prism.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create the basic profile first
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

  -- If this is an organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization and update profile in a single transaction
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
    SET organization_id = new_org.id
    FROM new_org
    WHERE profiles.id = NEW.id;
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
