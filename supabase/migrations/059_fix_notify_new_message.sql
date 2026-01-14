-- Fix notify_new_message to work with chat_messages schema
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

  -- Get receiver's user_id (in this schema, profiles.id = profiles.user_id)
  v_receiver_user_id := NEW.receiver_id;

  -- Send notification to receiver
  PERFORM send_fcm_notification(
    v_receiver_user_id,
    '💬 New Message from ' || COALESCE(v_sender_name, 'Someone'),
    LEFT(NEW.content, 100),
    'message',
    jsonb_build_object(
      'message_id', NEW.id,
      'sender_id', NEW.sender_id
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

-- Test it
INSERT INTO chat_messages (sender_id, receiver_id, content, created_at)
VALUES (
  '2f8ece05-6b6f-494f-adce-62b138916391',  -- client
  'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b',  -- provider
  'TEST AFTER FIX: Should create notification',
  NOW()
);

-- Check if notification was created
SELECT 
  id,
  message_payload->>'title' as title,
  message_payload->>'body' as body,
  jsonb_array_length(message_payload->'tokens') as token_count,
  created_at
FROM notification_queue
ORDER BY created_at DESC
LIMIT 1;
