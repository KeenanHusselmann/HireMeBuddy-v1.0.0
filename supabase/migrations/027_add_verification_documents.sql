-- Add verification document fields to provider_profiles table

ALTER TABLE provider_profiles 
ADD COLUMN IF NOT EXISTS id_front_url TEXT,
ADD COLUMN IF NOT EXISTS id_back_url TEXT,
ADD COLUMN IF NOT EXISTS headshot_url TEXT,
ADD COLUMN IF NOT EXISTS service_photos_urls TEXT[],
ADD COLUMN IF NOT EXISTS documents_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS documents_reviewed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS documents_reviewed_by UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS verification_notes TEXT;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_provider_documents_status ON provider_profiles(documents_status);

-- Comment on columns
COMMENT ON COLUMN provider_profiles.id_front_url IS 'URL of ID document front photo';
COMMENT ON COLUMN provider_profiles.id_back_url IS 'URL of ID document back photo';
COMMENT ON COLUMN provider_profiles.headshot_url IS 'URL of provider headshot photo';
COMMENT ON COLUMN provider_profiles.service_photos_urls IS 'Array of URLs for service portfolio photos';
COMMENT ON COLUMN provider_profiles.documents_status IS 'Status: pending, approved, rejected';
COMMENT ON COLUMN provider_profiles.documents_reviewed_at IS 'Timestamp when documents were reviewed';
COMMENT ON COLUMN provider_profiles.documents_reviewed_by IS 'Admin user ID who reviewed the documents';
COMMENT ON COLUMN provider_profiles.verification_notes IS 'Admin notes about verification';
