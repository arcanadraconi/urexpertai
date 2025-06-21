-- Migration Bundle 5

-- 0047_small_lake.sql
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

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
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

    RAISE LOG 'Created employee profile for %', NEW.email;

  -- Handle regular user signup
  ELSE
    -- Create regular user profile
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

-- Drop existing policies
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
DROP POLICY IF EXISTS "Allow branch operations" ON branches;

-- Create proper RLS policies
CREATE POLICY "Allow organization code verification"
  ON organizations
  FOR SELECT
  USING (true);

CREATE POLICY "Allow organization creation"
  ON organizations
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

CREATE POLICY "Allow branch creation"
  ON branches
  FOR INSERT
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0048_throbbing_bridge.sql
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

-- 0049_heavy_crystal.sql
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
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization code verification" ON organizations;

-- Create simplified policies
CREATE POLICY "Allow all operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 0050_restless_ember.sql
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

-- 0051_restless_paper.sql
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

-- Update RLS policies
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;

-- Create simplified policies
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 0052_lively_cave.sql
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

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id INTO org_id
    FROM organizations 
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Get or create default branch
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

-- 0053_fragrant_queen.sql
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

-- 0054_bitter_garden.sql
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

-- 0055_fierce_plain.sql
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

-- 0056_foggy_feather.sql
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

-- Drop ALL existing policies first
DROP POLICY IF EXISTS "Allow all operations" ON organizations;
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization code verification" ON organizations;
DROP POLICY IF EXISTS "Allow public organization code verification" ON organizations;

-- Create new policy
CREATE POLICY "Enable all access"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
