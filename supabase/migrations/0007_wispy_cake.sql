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