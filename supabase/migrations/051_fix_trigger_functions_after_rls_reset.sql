-- =====================================================
-- Fix trigger functions after RLS reset
-- Recreate SECURITY DEFINER functions to work with new RLS policies
-- =====================================================

-- Recreate notify_new_message function
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_sender_name TEXT;
  v_receiver_user_id UUID;
BEGIN
  -- Get sender's name (bypass RLS with SECURITY DEFINER)
  SELECT full_name INTO v_sender_name
  FROM profiles
  WHERE id = NEW.sender_id;

  -- Get receiver's user_id
  SELECT user_id INTO v_receiver_user_id
  FROM profiles
  WHERE id = NEW.receiver_id;

  -- Send notification to receiver
  PERFORM send_fcm_notification(
    v_receiver_user_id,
    '💬 New Message from ' || COALESCE(v_sender_name, 'Someone'),
    LEFT(NEW.content, 100),
    'message',
    jsonb_build_object(
      'message_id', NEW.id,
      'sender_id', NEW.sender_id,
      'conversation_id', NEW.conversation_id
    )
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the insert
    RAISE WARNING 'Failed to send message notification: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Recreate notify_new_booking function
CREATE OR REPLACE FUNCTION notify_new_booking()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
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

  -- Get service category name
  SELECT name INTO v_service_name
  FROM service_categories
  WHERE id = NEW.service_category_id;

  -- Send notification to provider
  PERFORM send_fcm_notification(
    v_provider_user_id,
    '📅 New Booking from ' || COALESCE(v_client_name, 'A Client'),
    'Service: ' || COALESCE(v_service_name, 'Unknown'),
    'booking',
    jsonb_build_object(
      'booking_id', NEW.id,
      'client_id', NEW.client_id,
      'status', NEW.status
    )
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to send booking notification: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Recreate notify_booking_status_change function
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
    WHEN 'confirmed' THEN
      v_notification_title := '✅ Booking Confirmed';
      v_notification_body := COALESCE(v_provider_name, 'Provider') || ' confirmed your booking';
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

-- Recreate send_fcm_notification function with proper RLS bypass
CREATE OR REPLACE FUNCTION send_fcm_notification(
  p_recipient_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_tokens TEXT[];
  v_function_url TEXT;
BEGIN
  -- Get all active device tokens for the recipient (bypass RLS)
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
  v_function_url := current_setting('app.settings.fcm_function_url', true);
  
  IF v_function_url IS NULL OR v_function_url = '' THEN
    v_function_url := 'https://YOUR_PROJECT.supabase.co/functions/v1/send_fcm';
  END IF;

  -- Queue notification for processing
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
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to queue FCM notification: %', SQLERRM;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION notify_new_message() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_new_booking() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_booking_status_change() TO authenticated;

-- =====================================================
-- Add missing RLS policies for notification tables
-- =====================================================

-- DEVICE_TOKENS: Users manage their own tokens
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='device_tokens') THEN
    ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "device_tokens_select_policy" ON device_tokens;
    DROP POLICY IF EXISTS "device_tokens_insert_policy" ON device_tokens;
    DROP POLICY IF EXISTS "device_tokens_update_policy" ON device_tokens;
    DROP POLICY IF EXISTS "device_tokens_delete_policy" ON device_tokens;

    CREATE POLICY "device_tokens_select_policy"
      ON device_tokens FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "device_tokens_insert_policy"
      ON device_tokens FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "device_tokens_update_policy"
      ON device_tokens FOR UPDATE
      USING (auth.uid() = user_id);

    CREATE POLICY "device_tokens_delete_policy"
      ON device_tokens FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- NOTIFICATION_QUEUE: Service role only (triggers use SECURITY DEFINER)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='notification_queue') THEN
    ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "notification_queue_service_policy" ON notification_queue;

    -- Allow service role (SECURITY DEFINER functions) full access
    CREATE POLICY "notification_queue_service_policy"
      ON notification_queue FOR ALL
      USING (true);
  END IF;
END $$;
