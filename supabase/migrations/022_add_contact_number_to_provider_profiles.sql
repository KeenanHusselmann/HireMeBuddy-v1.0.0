-- Migration to add contact_number field to provider_profiles table

-- Add contact_number column to provider_profiles
ALTER TABLE provider_profiles 
ADD COLUMN IF NOT EXISTS contact_number TEXT;

-- Copy existing phone numbers from profiles table to provider_profiles
UPDATE provider_profiles pp
SET contact_number = p.phone
FROM profiles p
WHERE pp.id = p.id 
  AND pp.contact_number IS NULL 
  AND p.phone IS NOT NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_provider_profiles_contact_number 
ON provider_profiles(contact_number);

-- Log success
DO $$
BEGIN
  RAISE NOTICE 'contact_number column added and phone numbers migrated successfully';
END $$;
