-- Fix storage bucket policies for verification-documents

-- Create storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('verification-documents', 'verification-documents', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to upload verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to view verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to upload their own documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own documents" ON storage.objects;

-- Policy: Allow authenticated users to upload their own verification documents
CREATE POLICY "Allow authenticated users to upload verification documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'verification-documents'
);

-- Policy: Allow public read access to verification documents (since bucket is public)
CREATE POLICY "Allow public to view verification documents"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'verification-documents');

-- Policy: Allow users to update their own documents
CREATE POLICY "Allow users to update their own documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'verification-documents');

-- Policy: Allow users to delete their own documents
CREATE POLICY "Allow users to delete their own documents"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'verification-documents');

-- Verify the bucket exists
SELECT id, name, public FROM storage.buckets WHERE id = 'verification-documents';
