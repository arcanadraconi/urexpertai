/*
  # Fix organization signup trigger

  1. Changes
    - Combine profile and organization creation into a single transaction
    - Add proper error handling and logging
    - Fix organization code generation
    
  2. Security
    - Maintain RLS policies
    - Keep security definer attribute
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  org_code text;
BEGIN
  -- Start transaction
  BEGIN
    -- Handle organization admin signup
    IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
      -- Generate organization code
      org_code := generate_org_code();
      org_name := NEW.raw_user_meta_data->>'organizationName';
      
      -- Create organization first
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

      -- Then create admin profile with organization ID
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

      RAISE LOG 'Created organization % with ID % and admin profile for %', org_name, org_id, NEW.email;

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

      RAISE LOG 'Created regular user profile for %', NEW.email;
    END IF;

    -- Commit transaction
    RETURN NEW;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error in handle_new_user: %', SQLERRM;
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