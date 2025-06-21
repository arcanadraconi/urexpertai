CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
-- Update profile policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
-- ========== 0033_quick_spark.sql ==========
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