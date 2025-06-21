/*
  # Organization Support

  1. New Tables
    - `organizations`
      - Stores organization information
      - Includes name, admin, and unique code
    - Update `profiles` table
      - Add organization_id reference
      - Add branch_id reference
      - Update role enum to include 'nurse'

  2. Functions & Triggers
    - `generate_org_code()`
      - Generates unique organization codes
    - `handle_new_user()`
      - Handles user creation with organization support
      - Creates organization records
      - Sets up proper roles

  3. Security
    - Enable RLS on organizations table
    - Set up appropriate access policies
*/

-- Drop existing objects
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user;
DROP FUNCTION IF EXISTS generate_org_code;

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  admin_id UUID REFERENCES auth.users(id) NOT NULL,
  code TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on organizations
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Organization policies
CREATE POLICY "Organization admins can manage their organization"
  ON organizations FOR ALL
  USING (admin_id = auth.uid());

CREATE POLICY "Users can view their organization"
  ON organizations FOR SELECT
  USING (
    id IN (
      SELECT organization_id FROM profiles
      WHERE id = auth.uid()
    )
  );

-- Update profiles table
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id),
  ADD COLUMN IF NOT EXISTS branch_id UUID,
  DROP CONSTRAINT IF EXISTS profiles_role_check,
  ADD CONSTRAINT profiles_role_check 
    CHECK (role IN ('admin', 'reviewer', 'provider', 'nurse'));

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_organizations_admin_id ON organizations(admin_id);
CREATE INDEX IF NOT EXISTS idx_organizations_code ON organizations(code);
CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON profiles(organization_id);

-- Create function to generate organization codes
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  part TEXT;
  i INTEGER := 0;
  success BOOLEAN := false;
  max_attempts INTEGER := 10;
  attempt INTEGER := 0;
BEGIN
  WHILE NOT success AND attempt < max_attempts LOOP
    -- Generate four groups of 4 characters
    result := '';
    FOR i IN 1..4 LOOP
      -- Generate 4 characters
      part := '';
      FOR j IN 1..4 LOOP
        part := part || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
      END LOOP;
      
      -- Add the part with hyphen (except for last part)
      IF i < 4 THEN
        result := result || part || '-';
      ELSE
        result := result || part;
      END IF;
    END LOOP;
    
    -- Check if code already exists
    IF NOT EXISTS (SELECT 1 FROM organizations WHERE code = result) THEN
      success := true;
    END IF;
    
    attempt := attempt + 1;
  END LOOP;
  
  IF NOT success THEN
    RAISE EXCEPTION 'Could not generate unique organization code after % attempts', max_attempts;
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create branches table
CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) NOT NULL,
  name TEXT NOT NULL,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on branches
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;

-- Branch policies
CREATE POLICY "Organization admins can manage branches"
  ON branches FOR ALL
  USING (
    organization_id IN (
      SELECT id FROM organizations
      WHERE admin_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their branch"
  ON branches FOR SELECT
  USING (
    id IN (
      SELECT branch_id FROM profiles
      WHERE id = auth.uid()
    )
  );

-- Create indexes for branches
CREATE INDEX IF NOT EXISTS idx_branches_organization_id ON branches(organization_id);

-- Create trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create basic profile first
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
    CASE 
      WHEN NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN 'admin'
      WHEN NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN 'nurse'
      ELSE 'admin'
    END,
    NOW(),
    NOW()
  );

  -- If this is an organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    WITH new_org AS (
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
      RETURNING id
    ),
    new_branch AS (
      INSERT INTO branches (
        organization_id,
        name,
        location
      )
      SELECT 
        id,
        'Main Branch',
        'Default Location'
      FROM new_org
      RETURNING id, organization_id
    )
    UPDATE public.profiles
    SET 
      organization_id = new_branch.organization_id,
      branch_id = new_branch.id
    FROM new_branch
    WHERE profiles.id = NEW.id;
  
  -- If this is an employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    WITH org_info AS (
      SELECT o.id as org_id, b.id as branch_id
      FROM organizations o
      LEFT JOIN branches b ON b.organization_id = o.id
      WHERE o.code = NEW.raw_user_meta_data->>'organization_code'
      LIMIT 1
    )
    UPDATE public.profiles
    SET 
      organization_id = org_info.org_id,
      branch_id = org_info.branch_id
    FROM org_info
    WHERE profiles.id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;
ALTER FUNCTION generate_org_code() OWNER TO postgres;
