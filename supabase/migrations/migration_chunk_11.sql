  END IF;
END $$;
-- ========== 0028_cool_tree.sql ==========
/*
  # Add organization code generation function
  
  1. Changes
    - Add generate_org_code function to database
    - Update function to be security definer
    - Add proper error handling
*/

-- Create the generate_org_code function
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS text AS $$
DECLARE
  chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result text := '';
  i integer;
  j integer;
BEGIN
  -- Generate 4 groups of 4 characters
  FOR i IN 1..4 LOOP
    -- Generate 4 characters for each group
    FOR j IN 1..4 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    -- Add hyphen between groups (except after last group)
    IF i < 4 THEN
      result := result || '-';
    END IF;
  END LOOP;
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error generating organization code: %', SQLERRM;
  RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Ensure proper permissions
ALTER FUNCTION generate_org_code() OWNER TO postgres;
-- ========== 0030_falling_shore.sql ==========
-- Create function to verify organization code
CREATE OR REPLACE FUNCTION verify_organization_code(code_to_verify text)
RETURNS uuid AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Validate code format
  IF NOT (code_to_verify ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') THEN
    RAISE EXCEPTION 'Invalid organization code format';
  END IF;