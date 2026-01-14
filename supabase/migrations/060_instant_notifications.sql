-- Enable pg_net extension for HTTP requests
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Update send_fcm_notification to trigger instant processing
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
BEGIN
  -- Get all active device tokens for the recipient (bypass RLS with SECURITY DEFINER)
  SELECT ARRAY_AGG(token) INTO v_tokens
  FROM device_tokens
  WHERE user_id = p_recipient_id
    AND token IS NOT NULL
    AND token != '';

  -- If no tokens found, just log and continue
  IF v_tokens IS NULL OR array_length(v_tokens, 1) IS NULL THEN
    RAISE NOTICE 'No FCM tokens found for user %', p_recipient_id;
    RETURN;
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

  -- Trigger instant processing via HTTP call to edge function
  PERFORM net.http_post(
    url := 'https://vjpaolkqlumpyuxxmmvr.supabase.co/functions/v1/process_queue',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjkxNjc4MSwiZXhwIjoyMDY4NDkyNzgxfQ.iuZzBILhJ05jwYQgdamdhEMECWcOt3_vUSIei3Fgyj0',
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );

  RAISE NOTICE 'FCM notification queued for user % with % tokens and instant processing triggered', p_recipient_id, array_length(v_tokens, 1);
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail the transaction, just log
    RAISE WARNING 'Failed to queue FCM notification for user %: %', p_recipient_id, SQLERRM;
    RETURN;
END;
$$;

-- Test instant notification
INSERT INTO chat_messages (sender_id, receiver_id, content, created_at)
VALUES (
  '2f8ece05-6b6f-494f-adce-62b138916391',  -- client
  'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b',  -- provider
  'INSTANT TEST: Should arrive immediately',
  NOW()
);
