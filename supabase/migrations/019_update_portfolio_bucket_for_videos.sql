-- Update portfolio-images bucket to accept video files
UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/webp',
  'video/mp4',
  'video/mpeg',
  'video/quicktime',
  'video/x-msvideo',
  'video/webm'
]
WHERE id = 'portfolio-images';
