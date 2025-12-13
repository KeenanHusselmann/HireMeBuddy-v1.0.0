-- Create trigger to notify admins when new providers sign up

-- Function to create admin notification for new provider signup
CREATE OR REPLACE FUNCTION notify_admin_new_provider()
RETURNS TRIGGER AS $$
BEGIN
  -- Create notification for admins
  INSERT INTO admin_notifications (type, title, message, metadata)
  VALUES (
    'new_provider',
    'New Provider Registration',
    'A new provider has signed up and requires document verification',
    jsonb_build_object(
      'provider_id', NEW.id,
      'provider_name', (SELECT full_name FROM profiles WHERE id = NEW.id),
      'documents_status', NEW.documents_status,
      'created_at', NEW.created_at
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_notify_admin_new_provider ON provider_profiles;

-- Create trigger on provider_profiles INSERT
CREATE TRIGGER trigger_notify_admin_new_provider
  AFTER INSERT ON provider_profiles
  FOR EACH ROW
  EXECUTE FUNCTION notify_admin_new_provider();

-- Also notify when documents status changes to pending (in case of updates)
CREATE OR REPLACE FUNCTION notify_admin_documents_pending()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify if documents_status changed to 'pending'
  IF NEW.documents_status = 'pending' AND (OLD.documents_status IS NULL OR OLD.documents_status != 'pending') THEN
    INSERT INTO admin_notifications (type, title, message, metadata)
    VALUES (
      'documents_pending',
      'Documents Ready for Review',
      'Provider documents are ready for verification',
      jsonb_build_object(
        'provider_id', NEW.id,
        'provider_name', (SELECT full_name FROM profiles WHERE id = NEW.id),
        'documents_status', NEW.documents_status
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_notify_admin_documents_pending ON provider_profiles;

-- Create trigger on provider_profiles UPDATE
CREATE TRIGGER trigger_notify_admin_documents_pending
  AFTER UPDATE ON provider_profiles
  FOR EACH ROW
  WHEN (NEW.documents_status = 'pending')
  EXECUTE FUNCTION notify_admin_documents_pending();

-- Comment on function
COMMENT ON FUNCTION notify_admin_new_provider() IS 'Creates admin notification when new provider signs up';
COMMENT ON FUNCTION notify_admin_documents_pending() IS 'Creates admin notification when provider documents are ready for review';
