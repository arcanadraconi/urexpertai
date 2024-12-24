/*
  # Fix organization signup trigger

  1. Changes
    - Fix trigger function to properly create organization and profile records
    - Add better error handling and logging
    - Ensure proper order of operations
    
  2. Security
    - Maintain existing RLS policies
    - Keep security definer attribute for trigger function
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  org_code text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- Generate organization code first
      org_code := generate_org_code();
      org_name := NEW.raw_user_meta_data->>'organizationName';
      
      -- Create organization
      INSERT INTO organizations (
        name,
        admin_id,
        code
      )
      VALUES (
        org_name,
        NEW.id,
        org_code
      )
      RETURNING id INTO org_id;

      -- Create admin profile
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

      RAISE LOG 'Created organization % (ID: %) with code % for admin %', org_name, org_id, org_code, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error in organization signup: %', SQLERRM;
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