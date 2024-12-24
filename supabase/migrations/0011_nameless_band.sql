/*
  # Update User Profile Creation Logic
  
  1. Changes
    - Drop trigger before function
    - Update function to handle organization signup
    - Add better error handling
    - Fix organization code verification
*/

-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Now we can safely drop and recreate the functions
DROP FUNCTION IF EXISTS verify_organization_code(text);
DROP FUNCTION IF EXISTS handle_new_user();

-- Create function to verify organization codes
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

-- Create the profile creation trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  branch_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- Create organization with generated code
      INSERT INTO organizations (name, admin_id, code)
      VALUES (
        NEW.raw_user_meta_data->>'organizationName',
        NEW.id,
        generate_org_code()
      )
      RETURNING id, name INTO org_id, org_name;

      -- Create default branch
      INSERT INTO branches (organization_id, name, location)
      VALUES (org_id, org_name, 'Main Branch')
      RETURNING id INTO branch_id;

      -- Create admin profile
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,
        branch_id,
        full_name,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'admin',
        org_id,
        branch_id,
        org_name,
        NOW(),
        NOW()
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create organization: %', SQLERRM;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- Get organization details
      SELECT id, name INTO org_id, org_name
      FROM organizations
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

      -- Get or create branch
      SELECT id INTO branch_id
      FROM branches
      WHERE organization_id = org_id
      LIMIT 1;

      IF branch_id IS NULL THEN
        INSERT INTO branches (organization_id, name, location)
        VALUES (org_id, org_name, 'Main Branch')
        RETURNING id INTO branch_id;
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
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to process organization code: %', SQLERRM;
    END;

  -- Handle regular user signup
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
        COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
        NOW(),
        NOW()
      );
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

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code verification" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;

-- Policy for organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations 
  FOR SELECT
  USING (true);

-- Policy for organization creation
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL AND
    admin_id = auth.uid()
  );