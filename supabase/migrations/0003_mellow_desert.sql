/*
  # Add contact information to patients table

  1. Changes
    - Add gender column to patients table
    - Add contact_info JSONB column to store:
      - address
      - phone
      - email

  2. Security
    - Maintain existing RLS policies
*/

DO $$ 
BEGIN
  -- Add gender column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'patients' AND column_name = 'gender'
  ) THEN
    ALTER TABLE patients ADD COLUMN gender TEXT;
  END IF;

  -- Add contact_info column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'patients' AND column_name = 'contact_info'
  ) THEN
    ALTER TABLE patients ADD COLUMN contact_info JSONB DEFAULT '{}'::jsonb;
  END IF;
END $$;