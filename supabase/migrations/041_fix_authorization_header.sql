-- Fix: Update database trigger to pass Authorization header
-- This fixes the 401 Unauthorized error from the edge function

CREATE OR REPLACE FUNCTION send_fcm_notification_immediate(
  p_recipient_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
DECLARE
  v_edge_function_url TEXT;
  v_service_role_key TEXT;
  v_request_id BIGINT;
BEGIN
  -- Hardcoded production configuration
  v_edge_function_url := 'https://vjpaolkqlumpyuxxmmvr.supabase.co/functions/v1/enqueue_and_send';
  v_service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjkxNjc4MSwiZXhwIjoyMDY4NDkyNzgxfQ.iuZzBILhJ05jwYQgdamdhEMECWcOt3_vUSIei3Fgyj0';

  -- Make async HTTP request with Authorization header
  SELECT net.http_post(
    url := v_edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'recipient_id', p_recipient_id::text,
      'message_payload', jsonb_build_object(
        'title', p_title,
        'body', p_body,
        'type', p_type
      ),
      'data', p_data
    )
  ) INTO v_request_id;

  RAISE NOTICE 'FCM notification sent via edge function (request_id: %)', v_request_id;
  
EXCEPTION WHEN OTHERS THEN
  -- If direct call fails, fallback to queue
  RAISE WARNING 'Failed to send FCM directly (%), queuing instead', SQLERRM;
  INSERT INTO notification_queue (recipient_id, message_payload, processed)
  VALUES (
    p_recipient_id,
    jsonb_build_object(
      'title', p_title,
      'body', p_body,
      'type', p_type,
      'data', p_data
    ),
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Validation message
DO $$
BEGIN
  RAISE NOTICE '✅ Fixed: Authorization header now included in pg_net requests';
  RAISE NOTICE '   Database trigger will now pass service role key to edge function';
  RAISE NOTICE '';
  RAISE NOTICE '🧪 Test again: Create a new booking and check for notification';
END $$;
