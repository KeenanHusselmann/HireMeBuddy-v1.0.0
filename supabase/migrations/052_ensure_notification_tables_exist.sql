-- =====================================================
-- Ensure notification_queue table exists and fix FCM
-- =====================================================

-- Create notification_queue if it doesn't exist
CREATE TABLE IF NOT EXISTS notification_queue (
  id BIGSERIAL PRIMARY KEY,
  recipient_id UUID NOT NULL,
  message_payload JSONB,
  processed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Create device_tokens if it doesn't exist
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT CHECK (platform IN ('android', 'ios', 'web')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- Enable RLS
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "notification_queue_service_policy" ON notification_queue;
DROP POLICY IF EXISTS "device_tokens_select_policy" ON device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_policy" ON device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_policy" ON device_tokens;
DROP POLICY IF EXISTS "device_tokens_delete_policy" ON device_tokens;

-- Create notification_queue policy (allow SECURITY DEFINER functions)
CREATE POLICY "notification_queue_service_policy"
  ON notification_queue FOR ALL
  USING (true);

-- Create device_tokens policies
-- Allow SECURITY DEFINER functions to read all tokens (for sending notifications)
CREATE POLICY "device_tokens_select_policy"
  ON device_tokens FOR SELECT
  USING (
    auth.uid() = user_id OR  -- User can read own tokens
    current_setting('role') = 'service_role' OR  -- Service role can read all
    auth.uid() IS NULL  -- Allow SECURITY DEFINER functions
  );

CREATE POLICY "device_tokens_insert_policy"
  ON device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens_update_policy"
  ON device_tokens FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "device_tokens_delete_policy"
  ON device_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- Recreate send_fcm_notification function
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

  RAISE NOTICE 'FCM notification queued for user % with % tokens', p_recipient_id, array_length(v_tokens, 1);
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail the transaction, just log
    RAISE NOTICE 'Failed to queue FCM notification: %', SQLERRM;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION send_fcm_notification(UUID, TEXT, TEXT, TEXT, JSONB) TO service_role;
