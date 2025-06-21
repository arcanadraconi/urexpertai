/*
  # Fix Existing Tables to Match Schema
  
  1. Table Renames
    - profiles → user_profiles
    - branches → organization_branches
  
  2. Table Structure Updates
    - Fix reports table structure
    - Fix organizations table structure
    - Update role definitions
  
  3. Maintain existing data and relationships
*/

-- First, let's create the role enum type for user_profiles
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'reviewer', 'provider', 'nurse', 'clinician', 'superadmin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Rename profiles table to user_profiles
ALTER TABLE IF EXISTS public.profiles RENAME TO user_profiles;

-- Rename branches table to organization_branches  
ALTER TABLE IF EXISTS public.branches RENAME TO organization_branches;

-- Update user_profiles table structure
ALTER TABLE public.user_profiles 
  DROP CONSTRAINT IF EXISTS profiles_role_check,
  ADD COLUMN IF NOT EXISTS first_name text,
  ADD COLUMN IF NOT EXISTS last_name text,
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

-- Update role column to use the enum (first add new column, copy data, drop old, rename)
DO $$
BEGIN
  -- Add new role column with enum type
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'role_new'
  ) THEN
    ALTER TABLE public.user_profiles ADD COLUMN role_new user_role;
    
    -- Copy existing role data
    UPDATE public.user_profiles SET role_new = role::user_role;
    
    -- Drop old role column and rename new one
    ALTER TABLE public.user_profiles DROP COLUMN role;
    ALTER TABLE public.user_profiles RENAME COLUMN role_new TO role;
    
    -- Make role NOT NULL
    ALTER TABLE public.user_profiles ALTER COLUMN role SET NOT NULL;
  END IF;
END
$$;

-- Update organizations table to match schema (rename code to unique_code)
ALTER TABLE public.organizations 
  RENAME COLUMN code TO unique_code;

-- Add missing columns to organization_branches if they don't exist
ALTER TABLE public.organization_branches
  ADD COLUMN IF NOT EXISTS branch_code text NOT NULL DEFAULT 'MAIN';

-- Update reports table structure to match the provided schema
-- Add missing columns
ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS title text,
  ADD COLUMN IF NOT EXISTS report_type text,
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS file_url text;

-- Add user_id column that references auth.users
ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS user_id uuid;

-- Update user_id to reference the provider_id for existing data
UPDATE public.reports SET user_id = provider_id WHERE user_id IS NULL;

-- Make user_id NOT NULL and add foreign key
ALTER TABLE public.reports 
  ALTER COLUMN user_id SET NOT NULL,
  ADD CONSTRAINT IF NOT EXISTS reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);

-- Update default values for new columns in reports
UPDATE public.reports 
SET 
  title = 'Legacy Report' WHERE title IS NULL,
  report_type = 'medical' WHERE report_type IS NULL;

-- Make required columns NOT NULL
ALTER TABLE public.reports 
  ALTER COLUMN title SET NOT NULL,
  ALTER COLUMN report_type SET NOT NULL;

-- Update RLS policies to use new table names
-- Drop old policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;

-- Create new policies for user_profiles
CREATE POLICY "Users can view their own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- Update foreign key references in other tables
-- Update user_metrics to reference user_profiles
ALTER TABLE public.user_metrics
  DROP CONSTRAINT IF EXISTS user_metrics_user_id_fkey,
  ADD CONSTRAINT user_metrics_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);

-- Update branch_id references in user_profiles to point to organization_branches
ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS profiles_branch_id_fkey,
  ADD CONSTRAINT user_profiles_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.organization_branches(id);

-- Update organization_id references in user_profiles
ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS profiles_organization_id_fkey,
  ADD CONSTRAINT user_profiles_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);

-- Update organization_branches foreign key
ALTER TABLE public.organization_branches
  DROP CONSTRAINT IF EXISTS branches_organization_id_fkey,
  ADD CONSTRAINT organization_branches_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);

-- Update reports foreign keys
ALTER TABLE public.reports
  DROP CONSTRAINT IF EXISTS reports_organization_id_fkey,
  ADD CONSTRAINT reports_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);

-- Update indexes to use new table names
DROP INDEX IF EXISTS idx_profiles_organization_id;
DROP INDEX IF EXISTS idx_profiles_branch_id;
DROP INDEX IF EXISTS idx_branches_organization_id;

CREATE INDEX IF NOT EXISTS idx_user_profiles_organization_id ON public.user_profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_branch_id ON public.user_profiles(branch_id);
CREATE INDEX IF NOT EXISTS idx_organization_branches_organization_id ON public.organization_branches(organization_id);

-- Update the handle_new_user function to use new table names
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create basic profile first
  INSERT INTO public.user_profiles (
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
      WHEN NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN 'admin'::user_role
      WHEN NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN 'nurse'::user_role
      ELSE 'admin'::user_role
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
        unique_code
      )
      VALUES (
        NEW.raw_user_meta_data->>'organizationName',
        NEW.id,
        generate_org_code()
      )
      RETURNING id
    ),
    new_branch AS (
      INSERT INTO organization_branches (
        organization_id,
        name,
        branch_code,
        created_at,
        updated_at
      )
      SELECT 
        id,
        'Main Branch',
        'MAIN',
        NOW(),
        NOW()
      FROM new_org
      RETURNING id, organization_id
    )
    UPDATE public.user_profiles
    SET 
      organization_id = new_branch.organization_id,
      branch_id = new_branch.id
    FROM new_branch
    WHERE user_profiles.id = NEW.id;
  
  -- If this is an employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    WITH org_info AS (
      SELECT o.id as org_id, b.id as branch_id
      FROM organizations o
      LEFT JOIN organization_branches b ON b.organization_id = o.id
      WHERE o.unique_code = NEW.raw_user_meta_data->>'organization_code'
      LIMIT 1
    )
    UPDATE public.user_profiles
    SET 
      organization_id = org_info.org_id,
      branch_id = org_info.branch_id
    FROM org_info
    WHERE user_profiles.id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create default user settings for all existing users
INSERT INTO public.user_settings (user_id, created_at, updated_at)
SELECT id, created_at, updated_at 
FROM auth.users 
WHERE id NOT IN (SELECT user_id FROM public.user_settings)
ON CONFLICT (user_id) DO NOTHING;

-- Create default subscribers for all existing users
INSERT INTO public.subscribers (user_id, created_at, updated_at)
SELECT id, created_at, updated_at 
FROM auth.users 
WHERE id NOT IN (SELECT user_id FROM public.subscribers)
ON CONFLICT (user_id) DO NOTHING;