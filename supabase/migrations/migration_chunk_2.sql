-- Modify existing profiles table
ALTER TABLE profiles 
  DROP CONSTRAINT IF EXISTS profiles_role_check,
  ADD CONSTRAINT profiles_role_check 
    CHECK (role IN ('nurse', 'physician', 'clinician', 'admin', 'superadmin')),
  ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id),
  ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES branches(id);
-- Modify existing reports table
ALTER TABLE reports
  ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id),
  ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES branches(id);
-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
-- Organizations policies
CREATE POLICY "SuperAdmin can manage all organizations"
  ON organizations FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'superadmin'
    )
  );
CREATE POLICY "Admin can view their organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    admin_id = auth.uid() OR
    id IN (
      SELECT organization_id FROM profiles
      WHERE id = auth.uid()
    )
  );
-- Branches policies
CREATE POLICY "SuperAdmin can manage all branches"
  ON branches FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'superadmin'
    )
  );
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
-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_organizations_admin_id ON organizations(admin_id);
CREATE INDEX IF NOT EXISTS idx_organizations_code ON organizations(code);
CREATE INDEX IF NOT EXISTS idx_branches_organization_id ON branches(organization_id);
CREATE INDEX IF NOT EXISTS idx_branches_admin_id ON branches(admin_id);
CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_profiles_branch_id ON profiles(branch_id);
CREATE INDEX IF NOT EXISTS idx_reports_organization_id ON reports(organization_id);
CREATE INDEX IF NOT EXISTS idx_reports_branch_id ON reports(branch_id);
-- Insert SuperAdmin user
DO $$
BEGIN
  -- Create the SuperAdmin profile if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE email = 'arcanadraconi@gmail.com'
  ) THEN
    INSERT INTO profiles (
      id,
      email,
      role,
      created_at
    )
    SELECT
      id,
      'arcanadraconi@gmail.com',
      'superadmin',
      now()
    FROM auth.users
    WHERE email = 'arcanadraconi@gmail.com'
    LIMIT 1;
  END IF;
END $$;