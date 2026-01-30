-- Add terms_accepted_at column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMPTZ;

-- Add comment
COMMENT ON COLUMN profiles.terms_accepted_at IS 'Timestamp when user accepted terms and conditions';
