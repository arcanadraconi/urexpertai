/*
  # Fix Organization Code Signup Process

  1. Changes
    - Add function to verify organization code and get organization ID
    - Update profile trigger to handle organization assignment
    - Add policy for organization code verification

  2. Security
    - Ensure proper access control for organization code verification
    - Maintain RLS policies
*/

-- Function to verify organization code and get organization ID
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  SELECT id INTO org_id
  FROM organizations
  WHERE code = code_to_verify;
  
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Invalid organization code';
  END IF;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the profile creation trigger to handle organization assignment
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Try to get organization ID if code is provided
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');
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
    CASE 
      WHEN org_id IS NOT NULL THEN 'clinician'
      WHEN NEW.raw_user_meta_data->>'role' IS NOT NULL THEN NEW.raw_user_meta_data->>'role'
      ELSE 'clinician'
    END,
    org_id,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add policy for organization code verification
CREATE POLICY "Allow organization code verification"
  ON organizations FOR SELECT
  USING (true);