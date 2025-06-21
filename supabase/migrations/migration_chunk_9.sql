$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Update organization policies to ensure proper access
DROP POLICY IF EXISTS "Allow organization code verification" ON organizations;
CREATE POLICY "Allow public organization code verification"
  ON organizations FOR SELECT
  USING (true);
-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
-- ========== 0010_patient_manor.sql ==========
/*
  # Fix Organization and Employee Signup

  1. Changes
    - Update profile creation trigger to handle organization admins
    - Update profile creation trigger to handle employees with organization codes
    - Add branch handling logic
    - Set proper roles
*/

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
  branch_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Get the organization name
    org_name := NEW.raw_user_meta_data->>'organizationName';
    -- Create organization
    INSERT INTO organizations (name, admin_id, code)
    VALUES (org_name, NEW.id, generate_org_code())
    RETURNING id INTO org_id;
    -- Create default branch (same as organization)
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
  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id, name INTO org_id, org_name
    FROM organizations
    WHERE code = NEW.raw_user_meta_data->>'organization_code';
    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;
    -- Get the first branch ID (or create one if none exists)
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
      'nurse', -- Default role for employees
      org_id,
      branch_id,
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
      COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
      NOW(),
      NOW()
    );
  END IF;