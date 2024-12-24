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