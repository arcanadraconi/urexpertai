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