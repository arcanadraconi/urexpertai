/*
  # Update organization and branch IDs to text format
  
  1. Changes
    - Drop dependent constraints and policies
    - Create new tables with text IDs
    - Migrate data
    - Update foreign key constraints
    - Recreate policies
    
  2. Security
    - Maintain RLS policies
    - Preserve data integrity
*/

-- First drop all dependent policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization updates" ON organizations;
DROP POLICY IF EXISTS "Organization admin can manage their branches" ON branches;
DROP POLICY IF EXISTS "Branch admin can view and update their branch" ON branches;

-- Drop dependent foreign key constraints
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_organization_id_fkey;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_branch_id_fkey;
ALTER TABLE branches DROP CONSTRAINT IF EXISTS branches_organization_id_fkey;
ALTER TABLE branches DROP CONSTRAINT IF EXISTS branches_admin_id_fkey;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_branch_id_fkey;

-- Create new tables with text IDs
CREATE TABLE organizations_new (
  id text PRIMARY KEY,
  name text NOT NULL,
  admin_id text NOT NULL,
  code text UNIQUE NOT NULL CHECK (length(code) = 19),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE branches_new (
  id text PRIMARY KEY,
  organization_id text NOT NULL,
  name text NOT NULL,
  location text NOT NULL,
  admin_id text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Copy data to new tables
INSERT INTO organizations_new (id, name, admin_id, code, created_at)
SELECT id::text, name, admin_id::text, code, created_at
FROM organizations;

INSERT INTO branches_new (id, organization_id, name, location, admin_id, created_at)
SELECT id::text, organization_id::text, name, location, admin_id::text, created_at
FROM branches;

-- Drop old tables
DROP TABLE branches;
DROP TABLE organizations;

-- Rename new tables
ALTER TABLE organizations_new RENAME TO organizations;
ALTER TABLE branches_new RENAME TO branches;

-- Update profiles table
ALTER TABLE profiles 
  ALTER COLUMN organization_id TYPE text USING organization_id::text,
  ALTER COLUMN branch_id TYPE text USING branch_id::text;

-- Update reports table
ALTER TABLE reports
  ALTER COLUMN branch_id TYPE text USING branch_id::text;

-- Recreate foreign key constraints
ALTER TABLE profiles 
  ADD CONSTRAINT profiles_organization_id_fkey 
  FOREIGN KEY (organization_id) REFERENCES organizations(id),
  ADD CONSTRAINT profiles_branch_id_fkey 
  FOREIGN KEY (branch_id) REFERENCES branches(id);

ALTER TABLE branches 
  ADD CONSTRAINT branches_organization_id_fkey 
  FOREIGN KEY (organization_id) REFERENCES organizations(id);

ALTER TABLE reports
  ADD CONSTRAINT reports_branch_id_fkey
  FOREIGN KEY (branch_id) REFERENCES branches(id);

-- Recreate policies
CREATE POLICY "Allow organization code lookup"
  ON organizations FOR SELECT
  USING (true);

CREATE POLICY "Allow organization creation"
  ON organizations FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow organization updates"
  ON organizations FOR UPDATE
  USING (admin_id = auth.uid());

CREATE POLICY "Organization admin can manage their branches"
  ON branches FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE id = branches.organization_id
      AND admin_id = auth.uid()
    )
  );

CREATE POLICY "Branch admin can view and update their branch"
  ON branches FOR SELECT
  TO authenticated
  USING (
    admin_id = auth.uid() OR
    id IN (
      SELECT branch_id FROM profiles
      WHERE id = auth.uid()
    )
  );

-- Update indexes
DROP INDEX IF EXISTS idx_organizations_admin_id;
DROP INDEX IF EXISTS idx_organizations_code;
DROP INDEX IF EXISTS idx_branches_organization_id;
DROP INDEX IF EXISTS idx_branches_admin_id;
DROP INDEX IF EXISTS idx_profiles_organization_id;
DROP INDEX IF EXISTS idx_profiles_branch_id;

CREATE INDEX idx_organizations_admin_id ON organizations(admin_id);
CREATE INDEX idx_organizations_code ON organizations(code);
CREATE INDEX idx_branches_organization_id ON branches(organization_id);
CREATE INDEX idx_branches_admin_id ON branches(admin_id);
CREATE INDEX idx_profiles_organization_id ON profiles(organization_id);
CREATE INDEX idx_profiles_branch_id ON profiles(branch_id);