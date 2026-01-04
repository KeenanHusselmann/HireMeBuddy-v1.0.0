-- Add debug logging to the booking status change trigger
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_provider_name TEXT;
  v_client_user_id UUID;
  v_title TEXT;
  v_body TEXT;
BEGIN
  -- Debug: Log trigger fired
  RAISE NOTICE 'Booking status change trigger fired for booking %', NEW.id;
  RAISE NOTICE 'Old status: %, New status: %', OLD.status, NEW.status;
  
  -- Only trigger if status actually changed
  IF OLD.status = NEW.status THEN
    RAISE NOTICE 'Status unchanged, skipping notification';
    RETURN NEW;
  END IF;

  -- Get provider's name
  SELECT full_name INTO v_provider_name
  FROM profiles
  WHERE id = NEW.provider_id;
  RAISE NOTICE 'Provider name: %', v_provider_name;

  -- Get client's user_id
  SELECT user_id INTO v_client_user_id
  FROM profiles
  WHERE id = NEW.client_id;
  RAISE NOTICE 'Client user_id: %', v_client_user_id;
  RAISE NOTICE 'Client profile id: %', NEW.client_id;

  -- Build notification based on new status
  CASE NEW.status
    WHEN 'accepted' THEN
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
      RAISE NOTICE 'Status % does not trigger notification', NEW.status;
      RETURN NEW;
  END CASE;

  RAISE NOTICE 'Sending notification: % - %', v_title, v_body;
  RAISE NOTICE 'Calling send_fcm_notification_immediate with recipient_id: %', v_client_user_id;

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

  RAISE NOTICE 'Notification function called successfully';
  RETURN NEW;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Error in notify_booking_status_change: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
