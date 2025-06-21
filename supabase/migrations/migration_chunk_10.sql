  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ========== 0013_tender_fountain.sql ==========
/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Update trigger function to handle organization signup
    - Add proper error handling
    - Fix policy conflicts
*/

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization with generated code
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
    -- Create admin profile with organization name as full name
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      full_name,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'admin',
      org_id,
      org_name,
      NOW(),
      NOW()
    );
  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id INTO org_id
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
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
-- Create new policy for organization code verification
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'organizations' 
    AND policyname = 'Allow organization code lookup'
  ) THEN
    CREATE POLICY "Allow organization code lookup"
      ON organizations 
      FOR SELECT
      USING (true);