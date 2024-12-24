/*
  # Fix Signup Error and Improve Error Handling

  1. Changes
    - Reorder profile and organization creation to prevent foreign key constraint issues
    - Add better error handling and logging
    - Add transaction management for atomic operations
    - Update RLS policies for better security

  2. Security
    - Maintain RLS policies for organizations and profiles
    - Ensure proper access control during signup process
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- First create the profile
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
        'admin',
        NOW(),
        NOW()
      );

      -- Generate organization code
      org_name := NEW.raw_user_meta_data->>'organizationName';

      -- Then create the organization
      INSERT INTO organizations (
        name, 
        admin_id, 
        code
      )
      VALUES (
        org_name,
        NEW.id,
        generate_org_code()
      )
      RETURNING id INTO org_id;

      -- Update the profile with organization info
      UPDATE public.profiles
      SET 
        organization_id = org_id,
        full_name = org_name
      WHERE id = NEW.id;

      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in organization signup: %', SQLERRM;
      RAISE;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First verify organization exists
      SELECT id, name INTO org_id, org_name
      FROM organizations 
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

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

      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in employee signup: %', SQLERRM;
      RAISE;
    END;

  -- Handle regular user signup (no organization)
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in regular signup: %', SQLERRM;
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

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization updates" ON organizations;

-- Allow organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

-- Allow organization creation during signup
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- Allow organization updates by admin
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (admin_id = auth.uid());