-- Drop existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS after_user_created ON auth.users;

-- Create a basic trigger function that only creates the profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create basic profile
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

  RETURN NEW;
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
DROP POLICY IF EXISTS "organizations_all_operations" ON organizations;
DROP POLICY IF EXISTS "branches_all_operations" ON branches;
DROP POLICY IF EXISTS "profiles_all_operations" ON profiles;
DROP POLICY IF EXISTS "Allow all operations" ON organizations;
DROP POLICY IF EXISTS "Allow all operations" ON branches;
DROP POLICY IF EXISTS "Allow all operations" ON profiles;

-- Create simple policies
CREATE POLICY "enable_all_access" ON organizations FOR ALL USING (true);
CREATE POLICY "enable_all_access" ON branches FOR ALL USING (true);
CREATE POLICY "enable_all_access" ON profiles FOR ALL USING (true);

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;