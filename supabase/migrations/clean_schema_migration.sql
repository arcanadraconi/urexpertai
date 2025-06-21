-- Clean URExpert Database Schema Migration
-- This creates the exact schema as specified, handling any existing tables

-- Drop existing tables if they exist (in reverse dependency order)
DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.user_sessions CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.user_metrics CASCADE;
DROP TABLE IF EXISTS public.subscribers CASCADE;
DROP TABLE IF EXISTS public.review_activities CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.access_keys CASCADE;
DROP TABLE IF EXISTS public.organization_branches CASCADE;
DROP TABLE IF EXISTS public.organizations CASCADE;

-- Drop old tables that were renamed
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.branches CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.patients CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.email_verifications CASCADE;
DROP TABLE IF EXISTS public.password_reset_tokens CASCADE;

-- Create enum for user roles if it doesn't exist
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'reviewer', 'provider', 'nurse');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 1. Organizations table (no dependencies)
CREATE TABLE public.organizations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  unique_code text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT organizations_pkey PRIMARY KEY (id)
);

-- 2. Organization branches (depends on organizations)
CREATE TABLE public.organization_branches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  organization_id uuid,
  name text NOT NULL,
  branch_code text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT organization_branches_pkey PRIMARY KEY (id),
  CONSTRAINT organization_branches_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE
);

-- 3. User profiles (depends on auth.users, organizations, organization_branches)
CREATE TABLE public.user_profiles (
  id uuid NOT NULL,
  email text NOT NULL,
  first_name text,
  last_name text,
  role user_role NOT NULL,
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

-- 4. Reports table (depends on auth.users, organizations)
CREATE TABLE public.reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  organization_id uuid,
  title text NOT NULL,
  report_type text NOT NULL,
  content text NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'draft'::text,
  file_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reports_pkey PRIMARY KEY (id),
  CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT reports_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL
);

-- 5. Access keys table (depends on auth.users)
CREATE TABLE public.access_keys (
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

-- 6. Review activities table (depends on auth.users, organizations)
CREATE TABLE public.review_activities (
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

-- 7. Subscribers table (depends on auth.users)
CREATE TABLE public.subscribers (
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

-- 8. User metrics table (depends on auth.users, organizations)
CREATE TABLE public.user_metrics (
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

-- 9. User sessions table (depends on auth.users)
CREATE TABLE public.user_sessions (
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

-- 10. User settings table (depends on auth.users)
CREATE TABLE public.user_settings (
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

-- Create indexes for better performance
CREATE INDEX idx_access_keys_user_id ON public.access_keys(user_id);
CREATE INDEX idx_access_keys_key_value ON public.access_keys(key_value) WHERE is_active = true;
CREATE INDEX idx_organization_branches_organization_id ON public.organization_branches(organization_id);
CREATE UNIQUE INDEX idx_organization_branches_branch_code ON public.organization_branches(branch_code);
CREATE INDEX idx_reports_user_id ON public.reports(user_id);
CREATE INDEX idx_reports_organization_id ON public.reports(organization_id);
CREATE INDEX idx_reports_status ON public.reports(status);
CREATE INDEX idx_reports_created_at ON public.reports(created_at DESC);
CREATE INDEX idx_review_activities_user_id ON public.review_activities(user_id);
CREATE INDEX idx_review_activities_organization_id ON public.review_activities(organization_id);
CREATE INDEX idx_review_activities_created_at ON public.review_activities(created_at DESC);
CREATE INDEX idx_user_profiles_organization_id ON public.user_profiles(organization_id);
CREATE INDEX idx_user_profiles_branch_id ON public.user_profiles(branch_id);
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX idx_user_sessions_last_active ON public.user_sessions(last_active DESC);

-- Enable Row Level Security on all tables
ALTER TABLE public.access_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for organizations
CREATE POLICY "Users can view their organization" ON public.organizations
  FOR SELECT USING (
    id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Admins can update their organization" ON public.organizations
  FOR UPDATE USING (
    id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Create RLS policies for organization_branches
CREATE POLICY "Users can view their organization branches" ON public.organization_branches
  FOR SELECT USING (
    organization_id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Admins can manage organization branches" ON public.organization_branches
  FOR ALL USING (
    organization_id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view profiles in their organization" ON public.user_profiles
  FOR SELECT USING (
    id = auth.uid() OR
    organization_id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can update their own profile" ON public.user_profiles
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Service role can manage all profiles" ON public.user_profiles
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Create RLS policies for reports
CREATE POLICY "Users can view reports in their organization" ON public.reports
  FOR SELECT USING (
    user_id = auth.uid() OR
    organization_id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can create reports" ON public.reports
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own reports" ON public.reports
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own reports" ON public.reports
  FOR DELETE USING (user_id = auth.uid());

-- Create RLS policies for access_keys
CREATE POLICY "Users can manage their own access keys" ON public.access_keys
  FOR ALL USING (user_id = auth.uid());

-- Create RLS policies for review_activities
CREATE POLICY "Users can view their own activities" ON public.review_activities
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create their own activities" ON public.review_activities
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all activities in their organization" ON public.review_activities
  FOR SELECT USING (
    organization_id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Create RLS policies for subscribers
CREATE POLICY "Users can manage their own subscription" ON public.subscribers
  FOR ALL USING (user_id = auth.uid());

-- Create RLS policies for user_metrics
CREATE POLICY "Users can view their own metrics" ON public.user_metrics
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view metrics in their organization" ON public.user_metrics
  FOR SELECT USING (
    organization_id IN (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Create RLS policies for user_sessions
CREATE POLICY "Users can manage their own sessions" ON public.user_sessions
  FOR ALL USING (user_id = auth.uid());

-- Create RLS policies for user_settings
CREATE POLICY "Users can manage their own settings" ON public.user_settings
  FOR ALL USING (user_id = auth.uid());

-- Create function to generate organization codes
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists BOOLEAN;
BEGIN
  LOOP
    -- Generate a random 6-character alphanumeric code
    code := UPPER(
      SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 3) ||
      SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 3)
    );
    
    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM organizations WHERE unique_code = code) INTO exists;
    
    -- If code doesn't exist, return it
    IF NOT exists THEN
      RETURN code;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create updated_at triggers for all tables
CREATE TRIGGER update_access_keys_updated_at BEFORE UPDATE ON public.access_keys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organization_branches_updated_at BEFORE UPDATE ON public.organization_branches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON public.reports
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

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  org_id UUID;
  branch_id UUID;
  org_code TEXT;
BEGIN
  -- Extract organization info from metadata
  org_id := (NEW.raw_user_meta_data->>'organization_id')::UUID;
  branch_id := (NEW.raw_user_meta_data->>'branch_id')::UUID;
  org_code := NEW.raw_user_meta_data->>'organization_code';

  -- Create user profile
  INSERT INTO public.user_profiles (
    id,
    email,
    first_name,
    last_name,
    role,
    organization_id,
    branch_id,
    is_active
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'provider'),
    org_id,
    branch_id,
    true
  );

  -- Handle organization creation for admins
  IF NEW.raw_user_meta_data->>'role' = 'admin' AND org_code IS NOT NULL THEN
    -- Check if organization exists
    SELECT id INTO org_id FROM public.organizations WHERE unique_code = org_code;
    
    IF org_id IS NULL THEN
      -- Create new organization
      INSERT INTO public.organizations (
        id,
        name,
        unique_code
      ) VALUES (
        gen_random_uuid(),
        COALESCE(NEW.raw_user_meta_data->>'organization_name', 'New Organization'),
        org_code
      ) RETURNING id INTO org_id;
      
      -- Create main branch
      INSERT INTO public.organization_branches (
        id,
        organization_id,
        name,
        branch_code
      ) VALUES (
        gen_random_uuid(),
        org_id,
        'Main Branch',
        org_code || '-MAIN'
      ) RETURNING id INTO branch_id;
      
      -- Update user profile with organization and branch
      UPDATE public.user_profiles 
      SET organization_id = org_id, 
          branch_id = branch_id 
      WHERE id = NEW.id;
    END IF;
  -- Handle employee signup with organization code
  ELSIF org_code IS NOT NULL THEN
    -- Find organization by code
    SELECT id INTO org_id FROM public.organizations WHERE unique_code = org_code;
    
    IF org_id IS NOT NULL THEN
      -- Get main branch if no branch specified
      IF branch_id IS NULL THEN
        SELECT id INTO branch_id 
        FROM public.organization_branches 
        WHERE organization_id = org_id 
        ORDER BY created_at ASC 
        LIMIT 1;
      END IF;
      
      -- Update user profile with organization and branch
      UPDATE public.user_profiles 
      SET organization_id = org_id, 
          branch_id = branch_id 
      WHERE id = NEW.id;
    END IF;
  END IF;

  -- Create user settings
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Create subscriber record
  INSERT INTO public.subscribers (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Create user metrics
  INSERT INTO public.user_metrics (user_id, organization_id)
  SELECT NEW.id, organization_id
  FROM public.user_profiles
  WHERE id = NEW.id
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: The trigger on auth.users needs to be created with superuser privileges
-- This will be in the auth_triggers.sql file

-- Grant permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;

-- Additional grants for authenticated users
GRANT INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.reports TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.access_keys TO authenticated;
GRANT INSERT ON public.review_activities TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.user_sessions TO authenticated;
GRANT INSERT, UPDATE ON public.user_settings TO authenticated;
GRANT UPDATE ON public.user_metrics TO authenticated;
GRANT UPDATE ON public.subscribers TO authenticated;

-- Create storage bucket for avatars if it doesn't exist
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  false,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for avatars
CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Anyone can view avatars" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Final verification query
DO $$
BEGIN
  RAISE NOTICE 'Schema creation completed successfully!';
  RAISE NOTICE 'Tables created: organizations, organization_branches, user_profiles, reports, access_keys, review_activities, subscribers, user_metrics, user_sessions, user_settings';
  RAISE NOTICE 'Remember to run auth_triggers.sql separately as it requires superuser privileges';
END $$;