-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a separate function for organization handling
CREATE OR REPLACE FUNCTION handle_organization_setup(
  user_id uuid,
  org_name text,
  org_code text DEFAULT NULL
)
RETURNS record AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  result record;
BEGIN
  -- Handle organization creation
  IF org_name IS NOT NULL THEN
    INSERT INTO organizations (name, admin_id, code)
    VALUES (org_name, user_id, COALESCE(org_code, generate_org_code()))
    RETURNING id INTO org_id;

    -- Create default branch
    INSERT INTO branches (organization_id, name, location)
    VALUES (org_id, 'Main Branch', 'Default Location')
    RETURNING id INTO branch_id;
  
  -- Handle existing organization
  ELSIF org_code IS NOT NULL THEN
    SELECT id INTO org_id
    FROM organizations 
    WHERE code = org_code;

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    SELECT id INTO branch_id
    FROM branches
    WHERE organization_id = org_id
    LIMIT 1;
  END IF;

  SELECT org_id, branch_id INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Simplify the main trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_result record;
BEGIN
  -- Handle organization setup first if needed
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    org_result := handle_organization_setup(
      NEW.id,
      NEW.raw_user_meta_data->>'organizationName'
    );
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    org_result := handle_organization_setup(
      NEW.id,
      NULL,
      NEW.raw_user_meta_data->>'organization_code'
    );
  END IF;

  -- Create the user profile
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
      WHEN NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN 'admin'
      WHEN NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN 'nurse'
      ELSE 'clinician'
    END,
    org_result.org_id,
    org_result.branch_id,
    NOW(),
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION handle_organization_setup(uuid, text, text) OWNER TO postgres;
ALTER FUNCTION handle_new_user() OWNER TO postgres;