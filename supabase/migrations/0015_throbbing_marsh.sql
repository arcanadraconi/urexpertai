/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Update trigger function to properly set organization_id in profiles
    - Add better error handling and logging
    - Fix organization code verification
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- First create the organization
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
      RETURNING id, name INTO org_id, org_name;

      -- Then create admin profile WITH organization ID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- Set organization ID for admin
        full_name,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'admin',
        org_id,  -- Link to the organization
        org_name,
        NOW(),
        NOW()
      );

      -- Log successful organization creation
      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create organization: %', SQLERRM;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First verify and get organization ID
      SELECT id, name INTO org_id, org_name
      FROM organizations 
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

      -- Then create employee profile WITH organization ID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- Set organization ID for employee
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'nurse',
        org_id,  -- Link to the organization
        NOW(),
        NOW()
      );

      -- Log successful employee profile creation
      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to process organization code: %', SQLERRM;
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

      -- Log successful regular user profile creation
      RAISE LOG 'Created regular user profile for %', NEW.email;
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