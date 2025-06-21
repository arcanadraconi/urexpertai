-- URExpert Database Schema
-- Generated on 2025-06-20T15:21:17.506Z


-- ========== 0001_square_meadow.sql ==========
/*
  # Initial Schema Setup for URExpert

  1. New Tables
    - `profiles`
      - Extends auth.users with additional user information
      - Stores user role and profile data
    - `reports`
      - Stores medical utilization reports
      - Includes status tracking and content
    - `patients`
      - Stores patient information
      - Links to reports

  2. Security
    - Enable RLS on all tables
    - Set up appropriate access policies
    - Ensure data privacy and HIPAA compliance
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'reviewer', 'provider')),
  full_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mrn TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create reports table
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  provider_id UUID REFERENCES profiles(id) NOT NULL,
  reviewer_id UUID REFERENCES profiles(id),
  status TEXT NOT NULL CHECK (status IN ('draft', 'submitted', 'reviewed', 'approved', 'rejected')),
  content JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Patients policies
CREATE POLICY "All authenticated users can view patients"
  ON patients FOR SELECT
  USING (true);

CREATE POLICY "Providers and admins can create patients"
  ON patients FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'provider')
    )
  );

-- Reports policies
CREATE POLICY "Users can view reports they are involved with"
  ON reports FOR SELECT
  USING (
    provider_id = auth.uid() OR 
    reviewer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "Providers can create reports"
  ON reports FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'provider'
    )
  );

CREATE POLICY "Users can update reports they own or review"
  ON reports FOR UPDATE
  USING (
    provider_id = auth.uid() OR 
    reviewer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reports_patient_id ON reports(patient_id);
CREATE INDEX IF NOT EXISTS idx_reports_provider_id ON reports(provider_id);
CREATE INDEX IF NOT EXISTS idx_reports_reviewer_id ON reports(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_patients_mrn ON patients(mrn);

-- ========== 0002_falling_truth.sql ==========
/*
  # Add Organizations and Branches Schema

  1. New Tables
    - `organizations`
      - `id` (uuid, primary key)
      - `name` (text)
      - `admin_id` (uuid)
      - `code` (text, 16-char unique)
      - `created_at` (timestamp)
    - `branches`
      - `id` (uuid, primary key)
      - `organization_id` (uuid, foreign key)
      - `name` (text)
      - `location` (text)
      - `admin_id` (uuid)
      - `created_at` (timestamp)

  2. Table Modifications
    - Add organization and branch references to existing tables
    - Update profiles table with role enum

  3. Security
    - Enable RLS
    - Add policies for organization and branch access
*/

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  admin_id UUID REFERENCES auth.users(id),
  code TEXT UNIQUE NOT NULL CHECK (length(code) = 16),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create branches table
CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  admin_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

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

-- ========== 0007_wispy_cake.sql ==========
/*
  # Fix Profile Creation and Organization Code Handling

  1. Changes
    - Add trigger to automatically create profiles for new users
    - Add function to generate organization codes
    - Add function to validate organization codes
    - Update organization code constraint

  2. Security
    - Enable RLS on profiles table
    - Add policies for profile access
*/

-- Function to generate organization codes
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS text AS $$
DECLARE
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  code text := '';
  i integer;
BEGIN
  FOR i IN 1..4 LOOP
    code := code || 
      substring(chars FROM floor(random() * length(chars) + 1)::integer FOR 1) ||
      substring(chars FROM floor(random() * length(chars) + 1)::integer FOR 1) ||
      substring(chars FROM floor(random() * length(chars) + 1)::integer FOR 1) ||
      substring(chars FROM floor(random() * length(chars) + 1)::integer FOR 1);
    IF i < 4 THEN
      code := code || '-';
    END IF;
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Function to validate organization codes
CREATE OR REPLACE FUNCTION validate_org_code(code text)
RETURNS boolean AS $$
BEGIN
  RETURN code ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$';
END;
$$ LANGUAGE plpgsql;

-- Update organization code constraint
ALTER TABLE organizations 
  DROP CONSTRAINT IF EXISTS organizations_code_check;

ALTER TABLE organizations 
  ADD CONSTRAINT organizations_code_check 
  CHECK (validate_org_code(code));

-- Create or replace the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
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
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add policy for organization code verification
CREATE POLICY "Allow organization code verification"
  ON organizations FOR SELECT
  USING (true);

-- ========== 0009_delicate_hall.sql ==========
/*
  # Fix Organization Code Verification

  1. Changes
    - Update organization code verification function
    - Add proper error handling
    - Ensure proper access control
*/

-- Drop existing function and recreate with better error handling
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Validate code format first
  IF NOT (code_to_verify ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') THEN
    RAISE EXCEPTION 'Invalid organization code format';
  END IF;

  -- Try to find organization
  SELECT id INTO org_id
  FROM organizations
  WHERE code = code_to_verify;
  
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Organization not found with the provided code';
  END IF;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Try to get organization ID if code is provided
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to verify organization code: %', SQLERRM;
    END;
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
    COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
    org_id,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
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

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========== 0013_tender_fountain.sql ==========
/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Update trigger function to handle organization signup
    - Add proper error handling
    - Fix policy conflicts
*/

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- Create organization with generated code
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
    RETURNING id, name INTO org_id, org_name;

    -- Create admin profile with organization name as full name
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      full_name,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      'admin',
      org_id,
      org_name,
      NOW(),
      NOW()
    );

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id INTO org_id
    FROM organizations 
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Create employee profile
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
      'nurse',
      org_id,
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
      'clinician',
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Create new policy for organization code verification
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'organizations' 
    AND policyname = 'Allow organization code lookup'
  ) THEN
    CREATE POLICY "Allow organization code lookup"
      ON organizations 
      FOR SELECT
      USING (true);
  END IF;
END $$;

-- ========== 0028_cool_tree.sql ==========
/*
  # Add organization code generation function
  
  1. Changes
    - Add generate_org_code function to database
    - Update function to be security definer
    - Add proper error handling
*/

-- Create the generate_org_code function
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS text AS $$
DECLARE
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result text := '';
  i integer;
  j integer;
BEGIN
  -- Generate 4 groups of 4 characters
  FOR i IN 1..4 LOOP
    -- Generate 4 characters for each group
    FOR j IN 1..4 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    
    -- Add hyphen between groups (except after last group)
    IF i < 4 THEN
      result := result || '-';
    END IF;
  END LOOP;

  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error generating organization code: %', SQLERRM;
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure proper permissions
ALTER FUNCTION generate_org_code() OWNER TO postgres;

-- ========== 0030_falling_shore.sql ==========
-- Create function to verify organization code
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Validate code format
  IF NOT (code_to_verify ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') THEN
    RAISE EXCEPTION 'Invalid organization code format';
  END IF;

  -- Find organization
  SELECT id INTO org_id
  FROM organizations
  WHERE code = code_to_verify;
  
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Organization not found with the provided code';
  END IF;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Handle employee signup with organization code
  IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Verify organization code and get organization ID
    org_id := verify_organization_code(NEW.raw_user_meta_data->>'organization_code');

    -- Create employee profile
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
      'nurse',
      org_id,
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
      'clinician',
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========== 0041_light_violet.sql ==========
/*
  # Add timestamps to branches table

  1. Changes
    - Add created_at and updated_at columns to branches table
    - Set default values using NOW()
    - Make columns non-nullable

  2. Notes
    - Uses IF NOT EXISTS to prevent errors if columns already exist
    - Adds columns in a safe way using DO block
*/

DO $$ 
BEGIN
  -- Add created_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;

  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
END $$;

-- ========== 0075_long_shadow.sql ==========
-- Add avatar_url column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Create storage bucket for avatars if it doesn't exist
INSERT INTO storage.buckets (id, name)
VALUES ('avatars', 'avatars')
ON CONFLICT DO NOTHING;

-- Enable RLS on storage
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create storage policies
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
