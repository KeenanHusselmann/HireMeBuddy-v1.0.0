-- Add first_name and last_name columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS first_name TEXT,
ADD COLUMN IF NOT EXISTS last_name TEXT;

-- Populate first_name from full_name (split on first space)
UPDATE profiles
SET first_name = CASE 
  WHEN full_name LIKE '% %' THEN SPLIT_PART(full_name, ' ', 1)
  ELSE full_name
END
WHERE first_name IS NULL;

-- Populate last_name from full_name (everything after first space)
UPDATE profiles
SET last_name = CASE 
  WHEN full_name LIKE '% %' THEN SUBSTRING(full_name FROM POSITION(' ' IN full_name) + 1)
  ELSE ''
END
WHERE last_name IS NULL;

-- Update the trigger to handle first_name and last_name
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, role, full_name, first_name, last_name, phone)
  VALUES (
    NEW.id,
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'client'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'first_name', SPLIT_PART(COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'), ' ', 1)),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    NEW.phone
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
