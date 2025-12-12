-- Create a function to send notifications that bypasses RLS
-- This function runs with SECURITY DEFINER (as the owner) so RLS doesn't apply

CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type notification_type
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
  VALUES (p_user_id, p_title, p_body, p_type, false, NOW())
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION send_notification(UUID, TEXT, TEXT, notification_type) TO authenticated;

-- Test the function (optional - comment out if you don't want to test)
-- SELECT send_notification(
--   '2f8ece05-6b6f-494f-adce-62b138916391'::UUID,
--   'Test Notification',
--   'This is a test',
--   'system'::notification_type
-- );
