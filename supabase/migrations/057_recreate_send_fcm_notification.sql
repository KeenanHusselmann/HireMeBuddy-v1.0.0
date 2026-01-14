-- Completely recreate send_fcm_notification function
DROP FUNCTION IF EXISTS send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB);

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
    -- Still create notification without tokens for debugging
    INSERT INTO notification_queue (recipient_id, message_payload, processed)
    VALUES (
      p_recipient_id,
      jsonb_build_object(
        'title', p_title,
        'body', p_body,
        'type', p_type,
        'data', p_data,
        'tokens', ARRAY[]::TEXT[]
      ),
      false
    );
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

  RAISE NOTICE 'FCM notification queued for user % with % tokens', p_recipient_id, array_length(v_tokens, 1);
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail the transaction, just log
    RAISE WARNING 'Failed to queue FCM notification for user %: %', p_recipient_id, SQLERRM;
    RETURN;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB) TO anon;

-- Test it immediately
SELECT send_fcm_notification(
  'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'::uuid,
  '🧪 Test After Recreation',
  'This should have tokens',
  'test',
  '{}'::jsonb
);

-- Check the result
SELECT 
  id,
  recipient_id,
  message_payload->>'title' as title,
  message_payload->>'body' as body,
  jsonb_array_length(message_payload->'tokens') as token_count,
  message_payload->'tokens' as tokens,
  created_at
FROM notification_queue
ORDER BY created_at DESC
LIMIT 1;
