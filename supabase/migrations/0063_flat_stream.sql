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