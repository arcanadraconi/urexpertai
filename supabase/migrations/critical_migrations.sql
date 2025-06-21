
-- 0001_square_meadow.sql
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

-- 0002_falling_truth.sql
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

-- 0007_wispy_cake.sql
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

-- 0016_snowy_truth.sql
/*
  # Fix Organization Signup Flow
  
  1. Changes
    - Update trigger function to properly handle organization signup
    - Fix organization ID reference in profiles table
    - Add better error handling and logging
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  org_name text;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    BEGIN
      -- First create the organization and get its UUID
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

      -- Then create admin profile with organization UUID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- This is UUID referencing organizations.id
        full_name,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'admin',
        org_id,  -- Using the UUID from organizations.id
        org_name,
        NOW(),
        NOW()
      );

      RAISE LOG 'Created organization % with ID % for admin %', org_name, org_id, NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create organization: %', SQLERRM;
    END;

  -- Handle employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    BEGIN
      -- First get organization UUID using the code
      SELECT id, name INTO org_id, org_name
      FROM organizations 
      WHERE code = NEW.raw_user_meta_data->>'organization_code';

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;

      -- Then create employee profile with organization UUID
      INSERT INTO public.profiles (
        id,
        email,
        role,
        organization_id,  -- This is UUID referencing organizations.id
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        'nurse',
        org_id,  -- Using the UUID from organizations.id
        NOW(),
        NOW()
      );

      RAISE LOG 'Created employee profile for % in organization %', NEW.email, org_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to process organization code: %', SQLERRM;
    END;

  -- Handle regular user signup (no organization)
  ELSE
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
        'clinician',
        NOW(),
        NOW()
      );

      RAISE LOG 'Created regular user profile for %', NEW.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create user profile: %', SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 0033_quick_spark.sql
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


-- 0062_shrill_cake.sql
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
  org_code text;
BEGIN
  -- Start transaction
  BEGIN
    -- Handle organization admin signup
    IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
      -- Generate organization code
      org_code := generate_org_code();
      
      -- Create organization
      INSERT INTO organizations (
        name,
        admin_id,
        code
      )
      VALUES (
        NEW.raw_user_meta_data->>'organizationName',
        NEW.id,
        org_code
      )
      RETURNING id INTO org_id;

      -- Create main branch
      INSERT INTO branches (
        organization_id,
        name,
        location,
        admin_id,
        created_at,
        updated_at
      )
      VALUES (
        org_id,
        'Main Branch',
        'Main Location',
        NEW.id,
        NOW(),
        NOW()
      )
      RETURNING id INTO branch_id;

      -- Create admin profile
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
        'admin',
        org_id,
        branch_id,
        NOW(),
        NOW()
      );

      RAISE LOG 'Created organization % (ID: %) with code % for admin %', 
        NEW.raw_user_meta_data->>'organizationName',
        org_id,
        org_code,
        NEW.email;

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
  EXCEPTION 
    WHEN unique_violation THEN
      RAISE LOG 'Unique constraint violation in handle_new_user for %: %', NEW.email, SQLERRM;
      RAISE;
    WHEN foreign_key_violation THEN
      RAISE LOG 'Foreign key violation in handle_new_user for %: %', NEW.email, SQLERRM;
      RAISE;
    WHEN OTHERS THEN
      RAISE LOG 'Error in handle_new_user for %: % %', NEW.email, SQLSTATE, SQLERRM;
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow organization operations" ON organizations;
DROP POLICY IF EXISTS "Allow all operations" ON organizations;

-- Create necessary policies
CREATE POLICY "Allow organization operations"
  ON organizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 0075_long_shadow.sql
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
