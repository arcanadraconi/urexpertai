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