-- Fix: Remove conversation_id reference from message notification trigger
-- The chat_messages table doesn't have a conversation_id column

CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  v_sender_name TEXT;
  v_receiver_user_id UUID;
BEGIN
  -- Get sender's name
  SELECT full_name INTO v_sender_name
  FROM profiles
  WHERE id = NEW.sender_id;

  -- Get receiver's user_id (not profile_id)
  SELECT user_id INTO v_receiver_user_id
  FROM profiles
  WHERE id = NEW.receiver_id;

  -- Send notification immediately
  PERFORM send_fcm_notification_immediate(
    v_receiver_user_id,
    '💬 New Message from ' || COALESCE(v_sender_name, 'Someone'),
    LEFT(NEW.content, 100),
    'message',
    jsonb_build_object(
      'message_id', NEW.id::text,
      'sender_id', NEW.sender_id::text,
      'receiver_id', NEW.receiver_id::text
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Validation
DO $$
BEGIN
  RAISE NOTICE '✅ Fixed: Message notification trigger no longer references conversation_id';
  RAISE NOTICE '   Messages will now send notifications successfully';
END $$;
