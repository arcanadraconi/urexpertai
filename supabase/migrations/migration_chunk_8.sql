END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Add policy for organization code verification
CREATE POLICY "Allow organization code verification"
  ON organizations FOR SELECT
  USING (true);
-- ========== 0009_delicate_hall.sql ==========
/*
  # Fix Organization Code Verification

  1. Changes
    - Update organization code verification function
    - Add proper error handling
    - Ensure proper access control
*/

-- Drop existing function and recreate with better error handling
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Validate code format first
  IF NOT (code_to_verify ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') THEN
    RAISE EXCEPTION 'Invalid organization code format';
  END IF;
  -- Try to find organization
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
  -- Try to get organization ID if code is provided
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to verify organization code: %', SQLERRM;
    END;
  END IF;
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
    COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
    org_id,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;