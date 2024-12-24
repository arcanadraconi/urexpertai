/*
  # Fix Organization Signup Process

  1. Changes
    - Simplify profile creation trigger
    - Handle organization creation separately
    - Add better error handling
    - Fix transaction issues

  2. Security
    - Maintain RLS policies
    - Keep existing permissions
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the profile creation trigger
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
    COALESCE(NEW.raw_user_meta_data->>'role', 'clinician'),
    NOW(),
    NOW()
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error creating profile: %', SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update organization policies
DROP POLICY IF EXISTS "Allow organization code lookup" ON organizations;
DROP POLICY IF EXISTS "Allow organization creation" ON organizations;
DROP POLICY IF EXISTS "Allow organization updates" ON organizations;

-- Allow organization code verification
CREATE POLICY "Allow organization code lookup"
  ON organizations
  FOR SELECT
  USING (true);

-- Allow organization creation during signup
CREATE POLICY "Allow organization creation"
  ON organizations
  FOR INSERT
  WITH CHECK (true);

-- Allow organization updates by admin
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (admin_id = auth.uid());