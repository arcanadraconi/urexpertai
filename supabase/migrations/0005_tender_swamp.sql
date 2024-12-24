/*
  # Update organization code format constraint

  1. Changes
    - Update the code format constraint to allow XXXX-XXXX-XXXX-XXXX format
    - Code can contain uppercase letters and numbers
*/

ALTER TABLE organizations 
  DROP CONSTRAINT IF EXISTS organizations_code_check;

ALTER TABLE organizations 
  ADD CONSTRAINT organizations_code_check 
  CHECK (code ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');