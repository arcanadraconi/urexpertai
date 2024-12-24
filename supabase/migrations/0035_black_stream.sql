-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create a simplified trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_id uuid;
  branch_id uuid;
BEGIN
  -- Start a subtransaction
  BEGIN
    -- If organization code is provided, verify it first
    IF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
      -- Get organization and branch IDs
      SELECT o.id, b.id INTO org_id, branch_id
      FROM organizations o
      LEFT JOIN branches b ON b.organization_id = o.id
      WHERE o.code = NEW.raw_user_meta_data->>'organization_code'
      LIMIT 1;

      IF org_id IS NULL THEN
        RAISE EXCEPTION 'Invalid organization code';
      END IF;
    END IF;

    -- Create the profile
    INSERT INTO public.profiles (
      id,
      email,
      role,
      organization_id,
      branch_id,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      CASE 
        WHEN NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN 'nurse'
        ELSE 'clinician'
      END,
      org_id,
      branch_id,
      NOW(),
      NOW()
    );

    RETURN NEW;
  EXCEPTION WHEN OTHERS THEN
    -- Log the error details
    RAISE LOG 'Error in handle_new_user for user %: %', NEW.email, SQLERRM;
    -- Re-raise the exception
    RAISE;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Update RLS policies
DROP POLICY IF EXISTS "Allow public organization code verification" ON organizations;

CREATE POLICY "Allow public organization code verification"
  ON organizations
  FOR SELECT
  USING (true);