-- Auth.users triggers for URExpert
-- These require superuser permissions and should be run in Supabase Dashboard

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the final version of the trigger function
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
  INSERT INTO public.users (
    id,
    email,
    full_name,
    role,
    organization_id,
    branch_id,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'provider'),
    org_id,
    branch_id,
    true,
    NOW(),
    NOW()
  );

  -- Handle organization creation for admins
  IF NEW.raw_user_meta_data->>'role' = 'admin' AND org_code IS NOT NULL THEN
    -- Check if organization exists
    SELECT id INTO org_id FROM public.organizations WHERE code = org_code;
    
    IF org_id IS NULL THEN
      -- Create new organization
      INSERT INTO public.organizations (
        id,
        name,
        code,
        created_by,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        COALESCE(NEW.raw_user_meta_data->>'organization_name', 'New Organization'),
        org_code,
        NEW.id,
        NOW(),
        NOW()
      ) RETURNING id INTO org_id;
      
      -- Create main branch
      INSERT INTO public.branches (
        id,
        organization_id,
        name,
        is_main,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        org_id,
        'Main Branch',
        true,
        NOW(),
        NOW()
      ) RETURNING id INTO branch_id;
      
      -- Update user with organization and branch
      UPDATE public.users 
      SET organization_id = org_id, 
          branch_id = branch_id 
      WHERE id = NEW.id;
    END IF;
  -- Handle employee signup with organization code
  ELSIF org_code IS NOT NULL THEN
    -- Find organization by code
    SELECT id INTO org_id FROM public.organizations WHERE code = org_code;
    
    IF org_id IS NOT NULL THEN
      -- Get main branch if no branch specified
      IF branch_id IS NULL THEN
        SELECT id INTO branch_id 
        FROM public.branches 
        WHERE organization_id = org_id AND is_main = true 
        LIMIT 1;
      END IF;
      
      -- Update user with organization and branch
      UPDATE public.users 
      SET organization_id = org_id, 
          branch_id = branch_id 
      WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role;