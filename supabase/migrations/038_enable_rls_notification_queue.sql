-- =====================================================
-- Enable RLS on notification_queue and device_tokens tables
-- Security Issue: Tables were exposed without RLS protection
-- Date: 2026-01-03
-- =====================================================

-- Enable Row Level Security on both tables
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Drop existing policies (if any) to start fresh
-- =====================================================

-- notification_queue policies
DROP POLICY IF EXISTS "Notification queue read access" ON notification_queue;
DROP POLICY IF EXISTS "System can insert notifications" ON notification_queue;
DROP POLICY IF EXISTS "System can update notification status" ON notification_queue;
DROP POLICY IF EXISTS "System can delete processed notifications" ON notification_queue;

-- device_tokens policies
DROP POLICY IF EXISTS "Users can read own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can insert own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can update own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can delete own device tokens" ON device_tokens;

-- =====================================================
-- RLS POLICIES FOR notification_queue (System-Only)
-- =====================================================

-- Policy 1: Only allow system/service to read notification queue
-- Users should NOT be able to directly query the notification queue
-- This is a backend-only table for processing
CREATE POLICY "System only read access"
  ON notification_queue
  FOR SELECT
  USING (false); -- No user access, system only

-- Policy 2: Only system can insert into notification queue
-- Users cannot directly create queue entries
CREATE POLICY "System only insert access"
  ON notification_queue
  FOR INSERT
  WITH CHECK (false); -- No user access, system only

-- Policy 3: Only system can update notification status
-- Users cannot modify queue processing status
CREATE POLICY "System only update access"
  ON notification_queue
  FOR UPDATE
  USING (false); -- No user access, system only

-- Policy 4: Only system can delete processed notifications
-- Users cannot delete queue entries
CREATE POLICY "System only delete access"
  ON notification_queue
  FOR DELETE
  USING (false); -- No user access, system only

-- =====================================================
-- RLS POLICIES FOR device_tokens (User-Specific)
-- =====================================================

-- Policy 1: Users can read their own device tokens
CREATE POLICY "Users can read own device tokens"
  ON device_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy 2: Users can insert their own device tokens
CREATE POLICY "Users can insert own device tokens"
  ON device_tokens
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy 3: Users can update their own device tokens
CREATE POLICY "Users can update own device tokens"
  ON device_tokens
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy 4: Users can delete their own device tokens
CREATE POLICY "Users can delete own device tokens"
  ON device_tokens
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- NOTES:
-- =====================================================
-- notification_queue:
--   - All policies set to 'false' means NO user access via anon key
--   - Service role key (server-side only) can still access this table
--   - Edge Functions and server-side code should use service role key
--   - Client apps should NEVER access notification_queue directly
--   - Notifications should be read from 'notifications' table instead
--
-- device_tokens:
--   - Users can manage their own FCM/APNS device tokens
--   - Required for push notification delivery
--   - Users can register, update, and remove their devices
--   - Cannot access other users' device tokens
--
-- SECURITY:
-- - notification_queue is a backend processing table
-- - device_tokens allows users to manage push notification endpoints
-- - Queue processing happens server-side via Edge Functions
-- =====================================================

-- Verify RLS is enabled
DO $$
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE relname = 'notification_queue') THEN
    RAISE EXCEPTION 'RLS not enabled on notification_queue!';
  END IF;
  
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE relname = 'device_tokens') THEN
    RAISE EXCEPTION 'RLS not enabled on device_tokens!';
  END IF;
  
  RAISE NOTICE '✅ RLS successfully enabled on notification_queue';
  RAISE NOTICE '✅ RLS successfully enabled on device_tokens';
  RAISE NOTICE '✅ 4 system-only policies created for notification_queue';
  RAISE NOTICE '✅ 4 user-specific policies created for device_tokens';
  RAISE NOTICE '⚠️  Users cannot access notification_queue (by design)';
  RAISE NOTICE '⚠️  Server-side code should use service role key for queue';
  RAISE NOTICE '✅ Users can manage their own device tokens';
END $$;
