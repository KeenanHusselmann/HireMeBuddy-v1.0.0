-- Migration: Device Token Cleanup and Lifecycle Management
-- Purpose: Add tracking and automatic cleanup of expired device tokens
-- Security: Priority 1 - Prevents token bloat and stale token issues

-- Step 1: Add last_used_at column to track token activity
ALTER TABLE device_tokens 
ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ DEFAULT NOW();

-- Step 2: Update existing tokens with current timestamp
UPDATE device_tokens 
SET last_used_at = created_at 
WHERE last_used_at IS NULL;

-- Step 3: Create index for efficient cleanup queries
CREATE INDEX IF NOT EXISTS idx_device_tokens_last_used 
ON device_tokens(last_used_at);

-- Step 4: Create function to cleanup stale tokens (older than 90 days)
CREATE OR REPLACE FUNCTION cleanup_stale_device_tokens()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Delete tokens that haven't been used in 90 days
  WITH deleted AS (
    DELETE FROM device_tokens
    WHERE last_used_at < NOW() - INTERVAL '90 days'
    RETURNING *
  )
  SELECT COUNT(*) INTO deleted_count FROM deleted;
  
  -- Log cleanup activity
  RAISE NOTICE 'Cleaned up % stale device tokens', deleted_count;
  
  RETURN deleted_count;
END;
$$;

-- Step 5: Create cron job to run cleanup weekly (requires pg_cron extension)
-- Note: This requires pg_cron extension to be enabled in Supabase
-- Run: SELECT cron.schedule('cleanup-stale-tokens', '0 2 * * 0', 'SELECT cleanup_stale_device_tokens()');

-- Step 6: Create trigger to update last_used_at when notification is queued
CREATE OR REPLACE FUNCTION update_token_last_used()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Update last_used_at for the device token when a notification is queued
  UPDATE device_tokens
  SET last_used_at = NOW()
  WHERE token = NEW.token;
  
  RETURN NEW;
END;
$$;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_update_token_last_used ON notification_queue;
CREATE TRIGGER trigger_update_token_last_used
  AFTER INSERT ON notification_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_token_last_used();

-- Step 7: Add comment for documentation
COMMENT ON COLUMN device_tokens.last_used_at IS 'Tracks when token was last used to send notification. Used for cleanup of stale tokens (90 day retention).';
COMMENT ON FUNCTION cleanup_stale_device_tokens() IS 'Deletes device tokens older than 90 days. Should be run weekly via cron job.';
COMMENT ON TRIGGER trigger_update_token_last_used ON notification_queue IS 'Updates device_tokens.last_used_at whenever a notification is queued.';

-- Step 8: Grant execute permission to authenticated users (for manual cleanup if needed)
GRANT EXECUTE ON FUNCTION cleanup_stale_device_tokens() TO authenticated;
