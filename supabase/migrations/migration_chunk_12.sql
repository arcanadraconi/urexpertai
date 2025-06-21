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
-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Handle employee signup with organization code
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Verify organization code and get organization ID
    org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');
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
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ========== 0041_light_violet.sql ==========
/*
  # Add timestamps to branches table

  1. Changes
    - Add created_at and updated_at columns to branches table
    - Set default values using NOW()
    - Make columns non-nullable

  2. Notes
    - Uses IF NOT EXISTS to prevent errors if columns already exist
    - Adds columns in a safe way using DO block
*/

DO $$ 
BEGIN
  -- Add created_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;