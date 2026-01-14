-- Migration: Add FCM notification triggers for messages and bookings
-- This will automatically send push notifications when users interact in the app

-- ============================================
-- 1. FUNCTION: Send FCM notification via HTTP
-- ============================================
CREATE OR REPLACE FUNCTION send_fcm_notification(
  p_recipient_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
DECLARE
  v_tokens TEXT[];
  v_function_url TEXT;
BEGIN
  -- Get all active device tokens for the recipient
  SELECT ARRAY_AGG(token) INTO v_tokens
  FROM device_tokens
  WHERE user_id = p_recipient_id
    AND token IS NOT NULL
    AND token != '';

  -- If no tokens found, log and exit
  IF v_tokens IS NULL OR array_length(v_tokens, 1) IS NULL THEN
    RAISE NOTICE 'No FCM tokens found for user %', p_recipient_id;
    RETURN;
  END IF;

  -- Call the Supabase Edge Function to send FCM
  -- Note: Replace with your actual function URL
  v_function_url := current_setting('app.settings.fcm_function_url', true);
  
  IF v_function_url IS NULL OR v_function_url = '' THEN
    v_function_url := 'https://YOUR_PROJECT.supabase.co/functions/v1/send_fcm';
  END IF;

  -- Use pg_net or http extension to call edge function
  -- This is a placeholder - you'll need to set up pg_net or use the queue approach
  INSERT INTO notification_queue (recipient_id, message_payload, processed)
  VALUES (
    p_recipient_id,
    jsonb_build_object(
      'title', p_title,
      'body', p_body,
      'type', p_type,
      'data', p_data,
      'tokens', v_tokens
    ),
    false
  );

  RAISE NOTICE 'FCM notification queued for user % with % tokens', p_recipient_id, array_length(v_tokens, 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 2. TRIGGER: New message notification
-- ============================================
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  v_sender_name TEXT;
  v_receiver_profile_id UUID;
BEGIN
  -- Get sender's name
  SELECT full_name INTO v_sender_name
  FROM profiles
  WHERE id = NEW.sender_id;

  -- Get receiver's user_id (not profile_id)
  SELECT user_id INTO v_receiver_profile_id
  FROM profiles
  WHERE id = NEW.receiver_id;

  -- Send notification to receiver
  PERFORM send_fcm_notification(
    v_receiver_profile_id,
    '💬 New Message from ' || COALESCE(v_sender_name, 'Someone'),
    LEFT(NEW.content, 100), -- Truncate long messages
    'message',
    jsonb_build_object(
      'message_id', NEW.id,
      'sender_id', NEW.sender_id,
      'conversation_id', NEW.conversation_id
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_new_message ON chat_messages;
CREATE TRIGGER trigger_notify_new_message
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_message();

-- ============================================
-- 3. TRIGGER: New booking notification
-- ============================================
CREATE OR REPLACE FUNCTION notify_new_booking()
RETURNS TRIGGER AS $$
DECLARE
  v_client_name TEXT;
  v_provider_user_id UUID;
  v_service_name TEXT;
BEGIN
  -- Get client's name
  SELECT full_name INTO v_client_name
  FROM profiles
  WHERE id = NEW.client_id;

  -- Get provider's user_id
  SELECT user_id INTO v_provider_user_id
  FROM profiles
  WHERE id = NEW.provider_id;

  -- Get service name if available (assuming bookings might reference services table)
  -- Modify this if your schema is different
  v_service_name := 'Service';

  -- Send notification to provider
  PERFORM send_fcm_notification(
    v_provider_user_id,
    '📦 New Booking Request',
    COALESCE(v_client_name, 'A client') || ' requested your service - NAD ' || NEW.total_price::TEXT,
    'booking',
    jsonb_build_object(
      'booking_id', NEW.id,
      'client_id', NEW.client_id,
      'booking_date', NEW.booking_date,
      'booking_time', NEW.booking_time,
      'total_price', NEW.total_price
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_new_booking ON bookings;
CREATE TRIGGER trigger_notify_new_booking
  AFTER INSERT ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_booking();

-- ============================================
-- 4. TRIGGER: Booking status change notification
-- ============================================
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
      RETURN NEW; -- Don't notify for other status changes
  END CASE;

  -- Send notification to client
  PERFORM send_fcm_notification(
    v_client_user_id,
    v_title,
    v_body,
    'booking_status',
    jsonb_build_object(
      'booking_id', NEW.id,
      'status', NEW.status,
      'provider_id', NEW.provider_id
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_booking_status_change ON bookings;
CREATE TRIGGER trigger_notify_booking_status_change
  AFTER UPDATE ON bookings
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION notify_booking_status_change();

-- ============================================
-- 5. GRANT PERMISSIONS
-- ============================================
-- Grant execute on notification function to authenticated users
GRANT EXECUTE ON FUNCTION send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION notify_new_message() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_new_booking() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_booking_status_change() TO authenticated;

-- ============================================
-- VALIDATION
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ FCM notification triggers installed successfully';
  RAISE NOTICE '   - New messages will trigger FCM notifications';
  RAISE NOTICE '   - New bookings will notify providers';
  RAISE NOTICE '   - Booking status changes will notify clients';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  IMPORTANT: Configure notification_queue processing';
  RAISE NOTICE '   - Deploy the process_queue edge function';
  RAISE NOTICE '   - Set up a cron job or periodic trigger';
END $$;
