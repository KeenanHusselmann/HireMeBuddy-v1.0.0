-- Create portfolio_images table for provider work samples
CREATE TABLE IF NOT EXISTS portfolio_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES provider_profiles(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_portfolio_images_provider_id 
ON portfolio_images(provider_id);

CREATE INDEX IF NOT EXISTS idx_portfolio_images_display_order 
ON portfolio_images(provider_id, display_order);

-- Enable RLS
ALTER TABLE portfolio_images ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Everyone can view portfolio images
CREATE POLICY "Anyone can view portfolio images"
ON portfolio_images FOR SELECT
USING (true);

-- Only the provider can insert their own portfolio images
CREATE POLICY "Providers can insert their own portfolio images"
ON portfolio_images FOR INSERT
WITH CHECK (auth.uid() = provider_id);

-- Only the provider can update their own portfolio images
CREATE POLICY "Providers can update their own portfolio images"
ON portfolio_images FOR UPDATE
USING (auth.uid() = provider_id);

-- Only the provider can delete their own portfolio images
CREATE POLICY "Providers can delete their own portfolio images"
ON portfolio_images FOR DELETE
USING (auth.uid() = provider_id);

-- Create storage bucket for portfolio images
INSERT INTO storage.buckets (id, name, public)
VALUES ('portfolio-images', 'portfolio-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for portfolio images bucket
CREATE POLICY "Anyone can view portfolio images"
ON storage.objects FOR SELECT
USING (bucket_id = 'portfolio-images');

CREATE POLICY "Authenticated users can upload portfolio images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'portfolio-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their own portfolio images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'portfolio-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own portfolio images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'portfolio-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
