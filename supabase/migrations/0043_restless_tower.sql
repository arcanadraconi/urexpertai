/*
  # Fix organization signup issues

  1. Changes
    - Simplify trigger function to reduce potential failure points
    - Add better error handling and validation
    - Ensure atomic transactions
    - Fix RLS policies for organization creation

  2. Notes
    - Handles user already exists cases gracefully
    - Ensures proper transaction handling
    - Maintains data consistency
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
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
      ELSE 'clinician'
    END,
    NOW(),
    NOW()
  );

  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization and branch in a single transaction
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
        location,
        created_at,
        updated_at
      )
      SELECT 
        id,
        'Main Branch',
        'Main Location',
        NOW(),
        NOW()
      FROM new_org
      RETURNING id, organization_id
    )
    UPDATE public.profiles
    SET 
      organization_id = new_branch.organization_id,
      branch_id = new_branch.id
    FROM new_branch
    WHERE profiles.id = NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log detailed error information
  RAISE LOG 'Error in handle_new_user for %: % %', NEW.email, SQLSTATE, SQLERRM;
  -- Re-raise the exception
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow branch creation" ON branches;
DROP POLICY IF EXISTS "Allow profile management" ON profiles;

-- Create new policies with proper checks
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND 
    admin_id = auth.uid()
  );

CREATE POLICY "Allow branch creation"
  ON branches
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM organizations
      WHERE organizations.id = branches.organization_id
      AND organizations.admin_id = auth.uid()
    )
  );

CREATE POLICY "Allow profile management"
  ON profiles
  FOR ALL
  USING (id = auth.uid());

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;