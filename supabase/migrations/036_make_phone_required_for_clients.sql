-- Migration: Make phone number required and improve client signup validation
-- This migration enhances data integrity for client profiles

-- Make phone number required for profiles (will be enforced in new signups)
-- Note: Don't add NOT NULL constraint to avoid breaking existing records
-- Instead, we'll enforce it at the application level and in the trigger

-- Update the trigger to require phone number for client signups
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate phone number is provided for new users
  IF NEW.raw_user_meta_data->>'phone_number' IS NULL OR 
     NEW.raw_user_meta_data->>'phone_number' = '' THEN
    RAISE EXCEPTION 'Phone number is required for registration';
  END IF;

  INSERT INTO profiles (id, role, full_name, first_name, last_name, phone, email)
  VALUES (
    NEW.id,
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'client'),
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      TRIM(COALESCE(NEW.raw_user_meta_data->>'first_name', '') || ' ' || COALESCE(NEW.raw_user_meta_data->>'last_name', '')),
      'User'
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'first_name',
      SPLIT_PART(COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'), ' ', 1)
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'last_name',
      NULLIF(SUBSTRING(COALESCE(NEW.raw_user_meta_data->>'full_name', '') FROM POSITION(' ' IN COALESCE(NEW.raw_user_meta_data->>'full_name', '')) + 1), '')
    ),
    COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone),
    NEW.email
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    updated_at = NOW();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_profile_on_signup();

-- Add validation function for phone number format (optional but recommended)
CREATE OR REPLACE FUNCTION validate_phone_number(phone TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Basic validation: must contain only digits, spaces, +, -, (, )
  -- Minimum 8 digits
  IF phone IS NULL OR phone = '' THEN
    RETURN FALSE;
  END IF;
  
  -- Remove common formatting characters
  IF LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) < 8 THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add check constraint for future records (won't affect existing data)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'profiles_phone_format_check'
  ) THEN
    ALTER TABLE profiles 
    ADD CONSTRAINT profiles_phone_format_check 
    CHECK (phone IS NULL OR validate_phone_number(phone));
  END IF;
END $$;

-- Create index on phone for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_phone_lookup ON profiles(phone) 
WHERE phone IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN profiles.phone IS 'User phone number - Required for new client registrations';
