-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  org_code text;
BEGIN
  -- Start transaction
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

      RAISE LOG 'Created organization % (ID: %) with code % for admin %', 
        NEW.raw_user_meta_data->>'organizationName',
        org_id,
        org_code,
        NEW.email;

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
  EXCEPTION 
    WHEN unique_violation THEN
      RAISE LOG 'Unique constraint violation in handle_new_user for %: %', NEW.email, SQLERRM;
      RAISE;
    WHEN foreign_key_violation THEN
      RAISE LOG 'Foreign key violation in handle_new_user for %: %', NEW.email, SQLERRM;
      RAISE;
    WHEN OTHERS THEN
      RAISE LOG 'Error in handle_new_user for %: % %', NEW.email, SQLSTATE, SQLERRM;
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

-- Drop existing policies
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
DROP POLICY IF EXISTS "Allow all operations" ON organizations;

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