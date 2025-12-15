-- Migration: Fix phone validation - make it optional but encouraged
-- This migration improves the trigger without blocking signups

-- Update the trigger to handle phone number gracefully (don't require it)
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Log the signup attempt
  RAISE NOTICE 'Creating profile for user: %', NEW.email;
  RAISE NOTICE 'Phone number from metadata: %', NEW.raw_user_meta_data->>'phone_number';
  
  INSERT INTO public.profiles (user_id, role, full_name, first_name, last_name, phone, email)
  VALUES (
    NEW.id,
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'client'),
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
    -- Use phone from metadata first, fallback to auth.users phone, or NULL
    COALESCE(
      NULLIF(TRIM(NEW.raw_user_meta_data->>'phone_number'), ''),
      NEW.phone,
      NULL
    ),
    NEW.email
  )
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    phone = COALESCE(EXCLUDED.phone, public.profiles.phone), -- Keep existing phone if new one is NULL
    email = EXCLUDED.email,
    updated_at = NOW();
    
  RAISE NOTICE 'Profile created successfully for: %', NEW.email;
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error creating profile: % - SQLSTATE: %', SQLERRM, SQLSTATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger (in case it doesn't exist)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_profile_on_signup();

-- Add validation function for phone number format (optional but recommended)
-- Supports Namibian formats: 081 234 5678, +264 81 234 5678
CREATE OR REPLACE FUNCTION validate_phone_number(phone TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  digit_count INTEGER;
BEGIN
  -- NULL or empty is acceptable
  IF phone IS NULL OR phone = '' THEN
    RETURN TRUE;
  END IF;
  
  -- Remove common formatting characters and count digits
  digit_count := LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'));
  
  -- Accept 9-13 digits (covers 081234567 to +264812345678)
  IF digit_count < 9 OR digit_count > 13 THEN
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
    CHECK (validate_phone_number(phone));
  END IF;
END $$;

-- Create index on phone for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_phone_lookup ON profiles(phone) 
WHERE phone IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN profiles.phone IS 'User phone number - Optional but recommended for better communication';
