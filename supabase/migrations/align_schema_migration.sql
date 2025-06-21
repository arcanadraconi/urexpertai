-- Migration to align database schema with the provided schema
-- This migration adds missing tables and updates existing ones

-- 1. First, let's rename existing tables to match the new schema
-- Note: We'll keep the old tables for now and migrate data later

-- 2. Create missing tables

-- Access Keys table for API access management
CREATE TABLE IF NOT EXISTS public.access_keys (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  key_type text NOT NULL,
  key_value text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT access_keys_pkey PRIMARY KEY (id),
  CONSTRAINT access_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create indexes for access_keys
CREATE INDEX IF NOT EXISTS idx_access_keys_user_id ON public.access_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_access_keys_key_value ON public.access_keys(key_value);

-- Organization branches (rename from branches)
CREATE TABLE IF NOT EXISTS public.organization_branches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  organization_id uuid,
  name text NOT NULL,
  branch_code text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT organization_branches_pkey PRIMARY KEY (id),
  CONSTRAINT organization_branches_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE
);

-- Create unique index on branch_code
CREATE UNIQUE INDEX IF NOT EXISTS idx_organization_branches_branch_code ON public.organization_branches(branch_code);

-- Migrate data from branches to organization_branches if branches exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'branches') THEN
    INSERT INTO public.organization_branches (id, organization_id, name, branch_code, created_at, updated_at)
    SELECT 
      id, 
      organization_id, 
      name,
      COALESCE(location, 'BRANCH-' || SUBSTRING(id::text, 1, 8)), -- Generate branch_code from location or id
      created_at, 
      updated_at
    FROM public.branches
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;

-- Update organizations table to have unique_code instead of code
DO $$
BEGIN
  -- Check if 'code' column exists and 'unique_code' doesn't
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'organizations' AND column_name = 'code')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'organizations' AND column_name = 'unique_code') THEN
    ALTER TABLE public.organizations RENAME COLUMN code TO unique_code;
  ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'organizations' AND column_name = 'unique_code') THEN
    ALTER TABLE public.organizations ADD COLUMN unique_code text NOT NULL DEFAULT generate_org_code();
    ALTER TABLE public.organizations ADD CONSTRAINT organizations_unique_code_key UNIQUE (unique_code);
  END IF;
END $$;

-- Review Activities table for tracking user activities
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
  CONSTRAINT review_activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT review_activities_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL
);

-- Create indexes for review_activities
CREATE INDEX IF NOT EXISTS idx_review_activities_user_id ON public.review_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_review_activities_organization_id ON public.review_activities(organization_id);
CREATE INDEX IF NOT EXISTS idx_review_activities_created_at ON public.review_activities(created_at);

-- Subscribers table for subscription management
CREATE TABLE IF NOT EXISTS public.subscribers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  subscribed boolean DEFAULT false,
  subscription_tier text,
  subscription_end timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT subscribers_pkey PRIMARY KEY (id),
  CONSTRAINT subscribers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- User Metrics table for analytics
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
  CONSTRAINT user_metrics_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL,
  CONSTRAINT user_metrics_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- User Profiles (update from profiles)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id uuid NOT NULL,
  email text NOT NULL,
  first_name text,
  last_name text,
  role text NOT NULL CHECK (role IN ('admin', 'reviewer', 'provider', 'nurse')),
  organization_id uuid,
  branch_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT user_profiles_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL,
  CONSTRAINT user_profiles_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.organization_branches(id) ON DELETE SET NULL
);

-- Migrate data from profiles to user_profiles if profiles exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    INSERT INTO public.user_profiles (id, email, first_name, last_name, role, organization_id, branch_id, is_active, created_at, updated_at)
    SELECT 
      id, 
      email,
      SPLIT_PART(full_name, ' ', 1) as first_name,
      SPLIT_PART(full_name, ' ', 2) as last_name,
      role,
      organization_id,
      branch_id,
      true as is_active,
      created_at,
      updated_at
    FROM public.profiles
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;

-- User Sessions table for session management
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  device_info text NOT NULL,
  location text,
  last_active timestamp with time zone NOT NULL DEFAULT now(),
  is_current boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create indexes for user_sessions
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_last_active ON public.user_sessions(last_active);

-- User Settings table for user preferences
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
  CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable Row Level Security on all new tables
ALTER TABLE public.access_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for access_keys
CREATE POLICY "Users can view their own access keys" ON public.access_keys
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create their own access keys" ON public.access_keys
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own access keys" ON public.access_keys
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own access keys" ON public.access_keys
  FOR DELETE USING (user_id = auth.uid());

-- Create RLS policies for organization_branches
CREATE POLICY "Organization members can view branches" ON public.organization_branches
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM public.user_profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Organization admins can manage branches" ON public.organization_branches
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create RLS policies for review_activities
CREATE POLICY "Users can view their own activities" ON public.review_activities
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create their own activities" ON public.review_activities
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Organization admins can view all activities" ON public.review_activities
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create RLS policies for subscribers
CREATE POLICY "Users can view their own subscription" ON public.subscribers
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own subscription" ON public.subscribers
  FOR UPDATE USING (user_id = auth.uid());

-- Create RLS policies for user_metrics
CREATE POLICY "Users can view their own metrics" ON public.user_metrics
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Organization admins can view all metrics" ON public.user_metrics
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM public.user_profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view their own profile" ON public.user_profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update their own profile" ON public.user_profiles
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Organization members can view profiles in their org" ON public.user_profiles
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM public.user_profiles WHERE id = auth.uid()
    )
  );

-- Create RLS policies for user_sessions
CREATE POLICY "Users can view their own sessions" ON public.user_sessions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own sessions" ON public.user_sessions
  FOR ALL USING (user_id = auth.uid());

-- Create RLS policies for user_settings
CREATE POLICY "Users can view their own settings" ON public.user_settings
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own settings" ON public.user_settings
  FOR ALL USING (user_id = auth.uid());

-- Create trigger to automatically create user settings
CREATE OR REPLACE FUNCTION create_user_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  INSERT INTO public.subscribers (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  INSERT INTO public.user_metrics (user_id, organization_id)
  SELECT NEW.id, organization_id
  FROM public.user_profiles
  WHERE id = NEW.id
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on user_profiles instead of auth.users (requires less permissions)
CREATE TRIGGER on_user_profile_created
  AFTER INSERT ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION create_user_settings();

-- Create updated_at triggers for all new tables
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_access_keys_updated_at BEFORE UPDATE ON public.access_keys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organization_branches_updated_at BEFORE UPDATE ON public.organization_branches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_review_activities_updated_at BEFORE UPDATE ON public.review_activities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscribers_updated_at BEFORE UPDATE ON public.subscribers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_metrics_updated_at BEFORE UPDATE ON public.user_metrics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON public.user_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT INSERT, UPDATE ON public.user_settings TO authenticated;
GRANT INSERT ON public.review_activities TO authenticated;
GRANT INSERT ON public.user_sessions TO authenticated;