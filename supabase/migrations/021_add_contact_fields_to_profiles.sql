-- Add phone and email fields to profiles table for contact information

-- Add email column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'email'
  ) THEN
    ALTER TABLE profiles ADD COLUMN email TEXT;
  END IF;
END $$;

-- Add phone column if it doesn't exist (rename from 'phone' to avoid conflicts)
DO $$ 
BEGIN
  -- Check if 'phone' column exists, if so, we're good
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'phone'
  ) THEN
    -- Column exists, do nothing
    NULL;
  ELSE
    -- Add phone column
    ALTER TABLE profiles ADD COLUMN phone TEXT;
  END IF;
END $$;

-- Add indexes for better performance on lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);

-- Add comments for documentation
COMMENT ON COLUMN profiles.email IS 'User email address for contact purposes';
COMMENT ON COLUMN profiles.phone IS 'User phone number for contact purposes';
