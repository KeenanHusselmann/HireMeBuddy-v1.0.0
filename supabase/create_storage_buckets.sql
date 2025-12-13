-- Create storage buckets for HireMeBuddy
-- Run this in Supabase SQL Editor

-- =====================================================
-- 1. Create portfolio-images bucket (for provider portfolios)
-- =====================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('portfolio-images', 'portfolio-images', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view portfolio images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload portfolio images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own portfolio images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own portfolio images" ON storage.objects;

-- Anyone can view portfolio images
CREATE POLICY "Anyone can view portfolio images"
ON storage.objects FOR SELECT
USING (bucket_id = 'portfolio-images');

-- Authenticated users can upload portfolio images
CREATE POLICY "Authenticated users can upload portfolio images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'portfolio-images' 
  AND auth.role() = 'authenticated'
);

-- Users can update their own portfolio images
CREATE POLICY "Users can update their own portfolio images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'portfolio-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own portfolio images
CREATE POLICY "Users can delete their own portfolio images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'portfolio-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- 2. Create profiles bucket (for user avatars)
-- =====================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;

-- Anyone can view profile images
CREATE POLICY "Anyone can view profile images"
ON storage.objects FOR SELECT
USING (bucket_id = 'profiles');

-- Authenticated users can upload profile images
CREATE POLICY "Authenticated users can upload profile images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profiles' 
  AND auth.role() = 'authenticated'
);

-- Users can update their own profile images
CREATE POLICY "Users can update their own profile images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own profile images
CREATE POLICY "Users can delete their own profile images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profiles' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
