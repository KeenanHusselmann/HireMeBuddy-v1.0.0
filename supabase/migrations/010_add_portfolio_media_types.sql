-- Add media_type column to portfolio_images table
ALTER TABLE portfolio_images
ADD COLUMN IF NOT EXISTS media_type VARCHAR(20) DEFAULT 'photo' CHECK (media_type IN ('photo', 'video'));

-- Update existing records to be photos
UPDATE portfolio_images SET media_type = 'photo' WHERE media_type IS NULL;

-- Create testimonials table
CREATE TABLE IF NOT EXISTS testimonials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES provider_profiles(id) ON DELETE CASCADE,
  client_name TEXT NOT NULL,
  client_avatar TEXT,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT NOT NULL,
  project_title TEXT,
  display_order INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_testimonials_provider_id 
ON testimonials(provider_id);

CREATE INDEX IF NOT EXISTS idx_testimonials_featured 
ON testimonials(provider_id, is_featured);

-- Enable RLS
ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for testimonials
CREATE POLICY "Anyone can view testimonials"
ON testimonials FOR SELECT
USING (true);

CREATE POLICY "Providers can insert their own testimonials"
ON testimonials FOR INSERT
WITH CHECK (auth.uid() = provider_id);

CREATE POLICY "Providers can update their own testimonials"
ON testimonials FOR UPDATE
USING (auth.uid() = provider_id);

CREATE POLICY "Providers can delete their own testimonials"
ON testimonials FOR DELETE
USING (auth.uid() = provider_id);
