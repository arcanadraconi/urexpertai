-- Drop existing trigger and functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user;
DROP FUNCTION IF EXISTS generate_org_code;

-- Create function to generate organization codes
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  part TEXT;
  i INTEGER := 0;
  success BOOLEAN := false;
  max_attempts INTEGER := 10;
  attempt INTEGER := 0;
BEGIN
  WHILE NOT success AND attempt < max_attempts LOOP
    -- Generate four groups of 4 characters
    result := '';
    FOR i IN 1..4 LOOP
      -- Generate 4 characters
      part := '';
      FOR j IN 1..4 LOOP
        part := part || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
      END LOOP;
      
      -- Add the part with hyphen (except for last part)
      IF i < 4 THEN
        result := result || part || '-';
      ELSE
        result := result || part;
      END IF;
    END LOOP;
    
    -- Check if code already exists
    IF NOT EXISTS (SELECT 1 FROM organizations WHERE code = result) THEN
      success := true;
    END IF;
    
    attempt := attempt + 1;
  END LOOP;
  
  IF NOT success THEN
    RAISE EXCEPTION 'Could not generate unique organization code after % attempts', max_attempts;
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  org_code TEXT;
  org_id uuid;
BEGIN
  -- If this is an organization signup
  IF NEW.raw_user_meta_data->>'organizationName' IS NOT NULL THEN
    -- 1. Generate organization code
    org_code := generate_org_code();
    
    -- 2. Create organization record
    INSERT INTO organizations (
      name,
      admin_id,
      code
    )
    VALUES (
      NEW.raw_user_meta_data->>'organizationName',
      NEW.id,
      org_code
    )
    RETURNING id INTO org_id;

    -- 3. Create admin profile with org ID
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

  -- If this is an employee signup with organization code
  ELSIF NEW.raw_user_meta_data->>'organization_code' IS NOT NULL THEN
    -- Get organization ID from code
    SELECT id INTO org_id
    FROM organizations 
    WHERE code = NEW.raw_user_meta_data->>'organization_code';

    IF org_id IS NULL THEN
      RAISE EXCEPTION 'Invalid organization code';
    END IF;

    -- Create employee profile
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
      'nurse',
      org_id,
      NOW(),
      NOW()
    );

  -- Regular user signup
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
      'admin',
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Ensure proper permissions
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;
ALTER FUNCTION generate_org_code() OWNER TO postgres;
