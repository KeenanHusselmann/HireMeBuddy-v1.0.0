-- Fix 1: Make trigger handle both 'accepted' AND 'confirmed' status
-- Fix 2: The trigger handles all notifications, so app shouldn't call RPC

CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_provider_name TEXT;
  v_client_user_id UUID;
  v_title TEXT;
  v_body TEXT;
BEGIN
  -- Only trigger if status actually changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get provider's name
  SELECT full_name INTO v_provider_name
  FROM profiles
  WHERE id = NEW.provider_id;

  -- Get client's user_id
  SELECT user_id INTO v_client_user_id
  FROM profiles
  WHERE id = NEW.client_id;

  -- Build notification based on new status
  CASE NEW.status
    WHEN 'accepted', 'confirmed' THEN  -- Handle BOTH statuses
      v_title := '✅ Booking Accepted';
      v_body := COALESCE(v_provider_name, 'Provider') || ' accepted your booking!';
    WHEN 'completed' THEN
      v_title := '🎉 Booking Completed';
      v_body := 'Your booking with ' || COALESCE(v_provider_name, 'provider') || ' is completed';
    WHEN 'cancelled' THEN
      v_title := '❌ Booking Cancelled';
      v_body := 'Your booking has been cancelled';
    WHEN 'rejected' THEN
      v_title := '❌ Booking Rejected';
      v_body := COALESCE(v_provider_name, 'Provider') || ' declined your booking';
    ELSE
      RETURN NEW;
  END CASE;

  -- Send notification immediately
  PERFORM send_fcm_notification_immediate(
    v_client_user_id,
    v_title,
    v_body,
    'booking_status',
    jsonb_build_object(
      'booking_id', NEW.id::text,
      'status', NEW.status,
      'provider_id', NEW.provider_id::text
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
