/*
  # Add Missing Tables for URExpert Schema Alignment
  
  1. New Tables
    - access_keys
    - subscribers
    - user_metrics
    - user_sessions
    - user_settings
    - review_activities
  
  2. Security
    - Enable RLS on all new tables
    - Add appropriate policies
*/

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

-- Enable RLS on all new tables
ALTER TABLE public.access_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_activities ENABLE ROW LEVEL SECURITY;

-- Create policies for access_keys
CREATE POLICY "Users can view their own access keys"
  ON public.access_keys FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own access keys"
  ON public.access_keys FOR ALL
  USING (auth.uid() = user_id);

-- Create policies for subscribers
CREATE POLICY "Users can view their own subscription"
  ON public.subscribers FOR SELECT
  USING (auth.uid() = user_id);

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
CREATE POLICY "Users can view their own sessions"
  ON public.user_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own sessions"
  ON public.user_sessions FOR ALL
  USING (auth.uid() = user_id);

-- Create policies for user_settings
CREATE POLICY "Users can view their own settings"
  ON public.user_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own settings"
  ON public.user_settings FOR ALL
  USING (auth.uid() = user_id);

-- Create policies for review_activities
CREATE POLICY "Users can view their own review activities"
  ON public.review_activities FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own review activities"
  ON public.review_activities FOR ALL
  USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_access_keys_user_id ON public.access_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_subscribers_user_id ON public.subscribers(user_id);
CREATE INDEX IF NOT EXISTS idx_user_metrics_user_id ON public.user_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_metrics_organization_id ON public.user_metrics(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_review_activities_user_id ON public.review_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_review_activities_organization_id ON public.review_activities(organization_id);