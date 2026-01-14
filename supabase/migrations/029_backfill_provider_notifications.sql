-- Backfill notifications for existing providers with pending documents

-- Insert notifications for all existing providers with documents
INSERT INTO admin_notifications (type, title, message, metadata, created_at)
SELECT 
  'new_provider',
  'New Provider Registration',
  'A new provider has signed up and requires document verification',
  jsonb_build_object(
    'provider_id', pp.id,
    'provider_name', p.full_name,
    'documents_status', pp.documents_status,
    'created_at', pp.created_at
  ),
  pp.created_at
FROM provider_profiles pp
JOIN profiles p ON pp.id = p.id
WHERE pp.documents_status = 'pending'
  AND NOT EXISTS (
    -- Don't create duplicate notifications
    SELECT 1 FROM admin_notifications 
    WHERE type IN ('new_provider', 'documents_pending')
      AND metadata->>'provider_id' = pp.id::text
  );

-- Comment
COMMENT ON TABLE admin_notifications IS 'Notifications for admin users. Backfilled existing pending providers.';
