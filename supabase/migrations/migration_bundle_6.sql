-- Migration Bundle 6

-- 0057_patient_tree.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function that properly handles organization creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_code text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Generate organization code
    org_code := generate_org_code();
    
    -- Create organization first
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

    RAISE LOG 'Created organization % with code % for admin %', NEW.raw_user_meta_data->>'organizationName', org_code, NEW.email;
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

-- Drop existing policies
DROP POLICY IF EXISTS "Enable all access" ON organizations;
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;

-- Create necessary policies
CREATE POLICY "Allow organization creation and lookup"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- 0058_heavy_dust.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function that properly handles organization creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_code text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- Generate organization code first
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

      RAISE LOG 'Created organization % with code % for admin %', NEW.raw_user_meta_data->>'organizationName', org_code, NEW.email;
    EXCEPTION WHEN OTHERS THEN
      -- Log the error and re-raise
      RAISE LOG 'Error creating organization: %', SQLERRM;
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

-- Drop existing policies
DROP POLICY IF EXISTS "Enable all access" ON organizations;
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation and lookup" ON organizations;

-- Create necessary policies
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- 0059_jolly_harbor.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function that properly handles organization creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_code text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- Generate organization code first (XXXX-XXXX-XXXX-XXXX format)
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

      RAISE LOG 'Created organization % with code % for admin %', 
        NEW.raw_user_meta_data->>'organizationName', 
        org_code, 
        NEW.email;

    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating organization: %', SQLERRM;
      RAISE;
    END;

    RETURN NEW;
  END IF;

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
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;

-- Create necessary policies
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- 0060_calm_hill.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function that properly handles organization creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  org_code text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- Generate organization code first
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
        location,
        admin_id,
        created_at,
        updated_at
      )
      VALUES (
        org_id,
        'Main Branch',
        'Main Location',
        NEW.id,
        NOW(),
        NOW()
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

      RAISE LOG 'Created organization % with code % for admin %', 
        NEW.raw_user_meta_data->>'organizationName', 
        org_code, 
        NEW.email;

    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in organization signup: %', SQLERRM;
      RAISE;
    END;
  
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
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation and lookup" ON organizations;

-- Create necessary policies
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0061_holy_jungle.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function with better error handling
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
      RETURNING id, code
    ),
    new_branch AS (
      INSERT INTO branches (
        organization_id,
        name,
        location,
        admin_id,
        created_at,
        updated_at
      )
      SELECT 
        id,
        'Main Branch',
        'Main Location',
        NEW.id,
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

-- Drop existing policies
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;

-- Create simplified policies
CREATE POLICY "Allow all operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- 0063_flat_stream.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function that creates profile first
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create basic profile first (this must succeed for auth to work)
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

  -- Return immediately to ensure user creation succeeds
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a separate function for organization setup
CREATE OR REPLACE FUNCTION public.setup_organization()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  org_code text;
BEGIN
  -- Only proceed if this is an organization signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
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

    -- Create main branch
    INSERT INTO branches (
      organization_id,
      name,
      location,
      admin_id,
      created_at,
      updated_at
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location',
      NEW.id,
      NOW(),
      NOW()
    )
    RETURNING id INTO branch_id;

    -- Update profile with organization info
    UPDATE public.profiles
    SET 
      role = 'admin',
      organization_id = org_id,
      branch_id = branch_id
    WHERE id = NEW.id;

    RAISE LOG 'Created organization % with code % for admin %', 
      NEW.raw_user_meta_data->>'organizationName',
      org_code,
      NEW.email;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in setup_organization for %: % %', NEW.email, SQLSTATE, SQLERRM;
  RETURN NEW; -- Continue even if org setup fails
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER after_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.setup_organization();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;
ALTER FUNCTION public.setup_organization() OWNER TO postgres;

-- Update RLS policies
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0064_purple_feather.sql
-- Drop existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS after_user_created ON auth.users;

-- Create trigger function that handles everything in a single transaction
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  org_code text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
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

    -- Create main branch
    INSERT INTO branches (
      organization_id,
      name,
      location,
      admin_id,
      created_at,
      updated_at
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location',
      NEW.id,
      NOW(),
      NOW()
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

    RAISE LOG 'Created organization % with code % for admin %', 
      NEW.raw_user_meta_data->>'organizationName',
      org_code,
      NEW.email;
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

-- Update RLS policies
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0065_raspy_crystal.sql
-- Drop existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS after_user_created ON auth.users;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
BEGIN
  -- Handle employee signup with organization code
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

  -- Handle organization admin signup
  ELSIF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
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

    -- Create default branch
    INSERT INTO branches (
      organization_id,
      name,
      location,
      admin_id,
      created_at,
      updated_at
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location',
      NEW.id,
      NOW(),
      NOW()
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
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0066_mellow_summit.sql
-- First verify and create necessary tables if they don't exist
DO $$ 
BEGIN
    -- Create organizations table if it doesn't exist
    CREATE TABLE IF NOT EXISTS public.organizations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        admin_id UUID REFERENCES auth.users(id),
        code TEXT UNIQUE NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Create branches table if it doesn't exist
    CREATE TABLE IF NOT EXISTS public.branches (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        admin_id UUID REFERENCES auth.users(id),
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Create profiles table if it doesn't exist
    CREATE TABLE IF NOT EXISTS public.profiles (
        id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
        email TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'nurse', 'clinician')),
        organization_id UUID REFERENCES organizations(id),
        branch_id UUID REFERENCES branches(id),
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );
END $$;

-- Drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger function
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

    -- Create default branch
    INSERT INTO branches (
      organization_id,
      name,
      location,
      admin_id,
      created_at,
      updated_at
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location',
      NEW.id,
      NOW(),
      NOW()
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

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Allow all operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow all operations"
  ON branches
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow all operations"
  ON profiles
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 0067_shy_ember.sql
-- First, ensure tables exist with proper constraints
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    admin_id UUID NOT NULL,
    code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    admin_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'nurse', 'clinician')),
    organization_id UUID REFERENCES organizations(id),
    branch_id UUID REFERENCES branches(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Drop existing triggers and policies
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS after_user_created ON auth.users;
DROP POLICY IF EXISTS "Allow all operations" ON organizations;
DROP POLICY IF EXISTS "Allow all operations" ON branches;
DROP POLICY IF EXISTS "Allow all operations" ON profiles;

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

  -- Return immediately to ensure user creation succeeds
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a separate function for organization setup
CREATE OR REPLACE FUNCTION public.setup_organization()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  org_code text;
BEGIN
  -- Only proceed if this is an organization signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
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

    -- Create main branch
    INSERT INTO branches (
      organization_id,
      name,
      location,
      admin_id
    )
    VALUES (
      org_id,
      'Main Branch',
      'Main Location',
      NEW.id
    )
    RETURNING id INTO branch_id;

    -- Update profile with organization info
    UPDATE public.profiles
    SET 
      role = 'admin',
      organization_id = org_id,
      branch_id = branch_id
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER after_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.setup_organization();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;
ALTER FUNCTION public.setup_organization() OWNER TO postgres;

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies with unique names
CREATE POLICY "organizations_all_operations" ON organizations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "branches_all_operations" ON branches FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "profiles_all_operations" ON profiles FOR ALL USING (true) WITH CHECK (true);
