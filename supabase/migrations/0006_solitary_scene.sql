/*
  # Add Profile Creation Trigger

  1. Changes
    - Add function to handle profile creation on user signup
    - Add trigger to automatically create profiles for new users
    - Set default role as 'clinician' for users without organization

  2. Security
    - Function is set to SECURITY DEFINER to run with elevated privileges
    - Function is owned by postgres to ensure it can always create profiles
*/

-- Create the function that will handle profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, created_at, updated_at)
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

-- Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;