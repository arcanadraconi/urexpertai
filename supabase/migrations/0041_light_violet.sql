/*
  # Add timestamps to branches table

  1. Changes
    - Add created_at and updated_at columns to branches table
    - Set default values using NOW()
    - Make columns non-nullable

  2. Notes
    - Uses IF NOT EXISTS to prevent errors if columns already exist
    - Adds columns in a safe way using DO block
*/

DO $$ 
BEGIN
  -- Add created_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;

  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE branches ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
END $$;