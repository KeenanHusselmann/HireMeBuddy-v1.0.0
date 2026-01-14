-- Fix notify_booking_status_change trigger to use 'accepted' instead of 'confirmed'
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_client_user_id UUID;
  v_provider_name TEXT;
  v_notification_title TEXT;
  v_notification_body TEXT;
BEGIN
  -- Only notify on status changes
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get client's user_id
  SELECT user_id INTO v_client_user_id
  FROM profiles
  WHERE id = NEW.client_id;

  -- Get provider's name
  SELECT full_name INTO v_provider_name
  FROM profiles
  WHERE id = NEW.provider_id;

  -- Set notification message based on new status
  CASE NEW.status
    WHEN 'accepted' THEN
      v_notification_title := '✅ Booking Accepted';
      v_notification_body := COALESCE(v_provider_name, 'Provider') || ' accepted your booking';
    WHEN 'in_progress' THEN
      v_notification_title := '🔧 Service Started';
      v_notification_body := COALESCE(v_provider_name, 'Provider') || ' started working on your service';
    WHEN 'completed' THEN
      v_notification_title := '✨ Service Completed';
      v_notification_body := 'Your service has been completed';
    WHEN 'cancelled' THEN
      v_notification_title := '❌ Booking Cancelled';
      v_notification_body := 'Your booking has been cancelled';
    ELSE
      RETURN NEW;
  END CASE;

  -- Send notification to client
  PERFORM send_fcm_notification(
    v_client_user_id,
    v_notification_title,
    v_notification_body,
    'booking_status',
    jsonb_build_object(
      'booking_id', NEW.id,
      'old_status', OLD.status,
      'new_status', NEW.status
    )
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to send booking status notification: %', SQLERRM;
    RETURN NEW;
END;
$$;

GRANT EXECUTE ON FUNCTION notify_booking_status_change() TO authenticated;
