-- First drop any existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create tables if they don't exist
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    admin_id UUID NOT NULL,
    code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'nurse', 'clinician')),
    organization_id UUID REFERENCES organizations(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Handle organization admin signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- First create organization
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
    RETURNING id INTO org_id;

    -- Then create admin profile
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
      'admin',
      org_id,
      NOW(),
      NOW()
    );

    RAISE LOG 'Created organization and admin profile for %', NEW.email;

  -- Handle regular user signup (no organization)
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
  RAISE LOG 'Error in handle_new_user: % %', SQLSTATE, SQLERRM;
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Drop existing policies
DROP POLICY IF EXISTS "org_access_20240324_v3" ON organizations;
DROP POLICY IF EXISTS "profile_access_20240324_v3" ON profiles;

-- Create new policies with unique names
CREATE POLICY "org_access_20240324_v4" ON organizations FOR ALL USING (true);
CREATE POLICY "profile_access_20240324_v4" ON profiles FOR ALL USING (true);

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;