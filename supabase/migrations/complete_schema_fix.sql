-- URExpert Complete Schema Fix
-- Execute this entire script in Supabase SQL Editor to align schema with requirements
-- Generated on 2025-06-20

-- ========== PART 1: ADD MISSING TABLES ==========

-- Create access_keys table
CREATE TABLE IF NOT EXISTS public.access_keys (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  key_type text NOT NULL,
  key_value text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT access_keys_pkey PRIMARY KEY (id),
  CONSTRAINT access_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create subscribers table
CREATE TABLE IF NOT EXISTS public.subscribers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  subscribed boolean DEFAULT false,
  subscription_tier text,
  subscription_end timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT subscribers_pkey PRIMARY KEY (id),
  CONSTRAINT subscribers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create user_metrics table
CREATE TABLE IF NOT EXISTS public.user_metrics (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  organization_id uuid,
  avg_review_time numeric DEFAULT 0,
  on_target_percent numeric DEFAULT 0,
  ai_success_rate numeric DEFAULT 0,
  time_saved_hours integer DEFAULT 0,
  reports_processed integer DEFAULT 0,
  pending_reviews integer DEFAULT 0,
  avg_processing_time numeric DEFAULT 0,
  accuracy_rate numeric DEFAULT 0,
  error_reduction numeric DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_metrics_pkey PRIMARY KEY (id),
  CONSTRAINT user_metrics_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id),
  CONSTRAINT user_metrics_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create user_sessions table
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  device_info text NOT NULL,
  location text,
  last_active timestamp with time zone NOT NULL DEFAULT now(),
  is_current boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create user_settings table
CREATE TABLE IF NOT EXISTS public.user_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  font_size text DEFAULT 'default'::text CHECK (font_size = ANY (ARRAY['small'::text, 'default'::text, 'large'::text])),
  email_notifications boolean DEFAULT true,
  sms_notifications boolean DEFAULT false,
  push_notifications boolean DEFAULT true,
  updates_notifications boolean DEFAULT true,
  news_notifications boolean DEFAULT false,
  announcements_notifications boolean DEFAULT true,
  two_factor_enabled boolean DEFAULT false,
  two_factor_phone text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_settings_pkey PRIMARY KEY (id),
  CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create review_activities table
CREATE TABLE IF NOT EXISTS public.review_activities (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  organization_id uuid,
  review_type text NOT NULL,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone,
  duration_minutes numeric,
  status text NOT NULL DEFAULT 'pending'::text,
  ai_assisted boolean DEFAULT false,
  accuracy_score numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT review_activities_pkey PRIMARY KEY (id),
  CONSTRAINT review_activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT review_activities_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);

-- ========== PART 2: FIX EXISTING TABLES ==========

-- Create user_role enum type
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

-- Update organizations table (rename code to unique_code)
ALTER TABLE public.organizations 
  RENAME COLUMN code TO unique_code;

-- Add missing columns to organization_branches
ALTER TABLE public.organization_branches
  ADD COLUMN IF NOT EXISTS branch_code text NOT NULL DEFAULT 'MAIN';

-- Update reports table structure
ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS title text,
  ADD COLUMN IF NOT EXISTS report_type text,
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS file_url text,
  ADD COLUMN IF NOT EXISTS user_id uuid;

-- Update user_id to reference provider_id for existing data
UPDATE public.reports SET user_id = provider_id WHERE user_id IS NULL;

-- Make user_id NOT NULL and add foreign key
ALTER TABLE public.reports
  ALTER COLUMN user_id SET NOT NULL;

-- Add foreign key constraint safely
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'reports_user_id_fkey'
    AND table_name = 'reports'
  ) THEN
    ALTER TABLE public.reports
    ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);
  END IF;
END $$;

-- Update default values for new columns
UPDATE public.reports 
SET 
  title = 'Legacy Report' WHERE title IS NULL,
  report_type = 'medical' WHERE report_type IS NULL;

-- Make required columns NOT NULL
ALTER TABLE public.reports 
  ALTER COLUMN title SET NOT NULL,
  ALTER COLUMN report_type SET NOT NULL;

-- ========== PART 3: ENABLE RLS AND CREATE POLICIES ==========

-- Enable RLS on new tables
ALTER TABLE public.access_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_activities ENABLE ROW LEVEL SECURITY;

-- Create policies for access_keys
CREATE POLICY "Users can manage their own access keys"
  ON public.access_keys FOR ALL
  USING (auth.uid() = user_id);

-- Create policies for subscribers
CREATE POLICY "Users can manage their own subscription"
  ON public.subscribers FOR ALL
  USING (auth.uid() = user_id);

-- Create policies for user_metrics
CREATE POLICY "Users can view their own metrics"
  ON public.user_metrics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own metrics"
  ON public.user_metrics FOR UPDATE
  USING (auth.uid() = user_id);

-- Create policies for user_sessions
CREATE POLICY "Users can manage their own sessions"
  ON public.user_sessions FOR ALL
  USING (auth.uid() = user_id);

-- Create policies for user_settings
CREATE POLICY "Users can manage their own settings"
  ON public.user_settings FOR ALL
  USING (auth.uid() = user_id);

-- Create policies for review_activities
CREATE POLICY "Users can manage their own review activities"
  ON public.review_activities FOR ALL
  USING (auth.uid() = user_id);

-- ========== PART 4: UPDATE FOREIGN KEYS AND INDEXES ==========

-- Update foreign key references
ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS profiles_branch_id_fkey,
  ADD CONSTRAINT user_profiles_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.organization_branches(id);

ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS profiles_organization_id_fkey,
  ADD CONSTRAINT user_profiles_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);

ALTER TABLE public.organization_branches
  DROP CONSTRAINT IF EXISTS branches_organization_id_fkey,
  ADD CONSTRAINT organization_branches_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);

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

-- Create indexes for new tables
CREATE INDEX IF NOT EXISTS idx_access_keys_user_id ON public.access_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_subscribers_user_id ON public.subscribers(user_id);
CREATE INDEX IF NOT EXISTS idx_user_metrics_user_id ON public.user_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_metrics_organization_id ON public.user_metrics(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_review_activities_user_id ON public.review_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_review_activities_organization_id ON public.review_activities(organization_id);

-- ========== PART 5: UPDATE FUNCTIONS ==========

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

-- ========== PART 6: POPULATE DEFAULT DATA ==========

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