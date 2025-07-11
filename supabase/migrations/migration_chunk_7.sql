-- ========== 0004_steep_cliff.sql ==========
/*
  # Organization RLS Policies
  
  1. New Policies
    - Allow organization creation during signup
    - Allow organization admins to manage their organizations
    - Allow users to view their organization
  
  2. Security
    - Enable RLS on organizations table
    - Add policies for create, read, update operations
*/

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow organization creation during signup" ON organizations;
DROP POLICY IF EXISTS "Allow organization admins to manage their organizations" ON organizations;
DROP POLICY IF EXISTS "Allow users to view their organization" ON organizations;
-- Create new policies
CREATE POLICY "Allow organization creation during signup"
ON organizations FOR INSERT
WITH CHECK (true);
CREATE POLICY "Allow organization admins to manage their organizations"
ON organizations FOR UPDATE
USING (admin_id = auth.uid())
WITH CHECK (admin_id = auth.uid());
CREATE POLICY "Allow users to view their organization"
ON organizations FOR SELECT
USING (
  id IN (
    SELECT organization_id 
    FROM profiles 
    WHERE id = auth.uid()
  )
  OR 
  admin_id = auth.uid()
);
-- ========== 0005_tender_swamp.sql ==========
/*
  # Update organization code format constraint

  1. Changes
    - Update the code format constraint to allow XXXX-XXXX-XXXX-XXXX format
    - Code can contain uppercase letters and numbers
*/

ALTER TABLE organizations 
  DROP CONSTRAINT IF EXISTS organizations_code_check;
ALTER TABLE organizations 
  ADD CONSTRAINT organizations_code_check 
  CHECK (code ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
-- ========== 0008_divine_pebble.sql ==========
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