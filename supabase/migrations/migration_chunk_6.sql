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
-- ========== 0003_mellow_desert.sql ==========
/*
  # Add contact information to patients table

  1. Changes
    - Add gender column to patients table
    - Add contact_info JSONB column to store:
      - address
      - phone
      - email

  2. Security
    - Maintain existing RLS policies
*/

DO $$ 
BEGIN
  -- Add gender column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'patients' AND column_name = 'gender'
  ) THEN
    ALTER TABLE patients ADD COLUMN gender TEXT;
  END IF;
  -- Add contact_info column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'patients' AND column_name = 'contact_info'
  ) THEN
    ALTER TABLE patients ADD COLUMN contact_info JSONB DEFAULT '{}'::jsonb;
  END IF;
END $$;