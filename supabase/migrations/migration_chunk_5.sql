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