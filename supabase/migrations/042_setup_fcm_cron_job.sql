-- Cron Job Setup for FCM Notification Processing
-- This sets up an automated job to process queued notifications every minute

-- ============================================
-- 1. Enable pg_cron extension
-- ============================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================
-- 2. Create job to process notification queue
-- ============================================
-- Run every minute
SELECT cron.schedule(
  'process-fcm-notifications',  -- Job name
  '*/1 * * * *',                -- Every 1 minute (cron format)
  $$
    -- Call the Supabase Edge Function to process queue
    SELECT net.http_post(
      url := current_setting('app.settings.supabase_url', true) || '/functions/v1/process_queue',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := '{}'::jsonb
    );
  $$
);

-- ============================================
-- 3. View scheduled jobs
-- ============================================
SELECT 
  jobid,
  schedule,
  command,
  active
FROM cron.job
WHERE jobname = 'process-fcm-notifications';

-- ============================================
-- MANUAL CONFIGURATION REQUIRED
-- ============================================
-- Before the cron job will work, you need to:
--
-- 1. Enable pg_cron in your Supabase project:
--    Go to: Database > Extensions > Enable "pg_cron"
--
-- 2. Enable pg_net extension:
--    Go to: Database > Extensions > Enable "pg_net"
--
-- 3. Set your Supabase URL:
--    ALTER DATABASE postgres SET app.settings.supabase_url = 'https://YOUR_PROJECT_REF.supabase.co';
--
-- 4. Set your service role key (from Dashboard > Settings > API):
--    ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
--
-- ============================================
-- TO UNSCHEDULE THE JOB
-- ============================================
-- SELECT cron.unschedule('process-fcm-notifications');
