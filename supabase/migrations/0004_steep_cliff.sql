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