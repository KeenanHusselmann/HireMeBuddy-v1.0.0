-- Fix FCM Cron Job - Remove dependency on database settings
-- This version doesn't require ALTER DATABASE permissions

-- ============================================
-- 1. Enable required extensions
-- ============================================
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ============================================
-- 2. Remove old cron job if exists (safe)
-- ============================================
DO $$
BEGIN
  PERFORM cron.unschedule('process-fcm-notifications');
EXCEPTION
  WHEN OTHERS THEN
    NULL; -- Ignore error if job doesn't exist
END $$;

-- ============================================
-- 3. Create secrets table in public schema
-- ============================================
CREATE TABLE IF NOT EXISTS public.cron_secrets (
  name TEXT PRIMARY KEY,
  secret TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create function to get service role key
CREATE OR REPLACE FUNCTION get_service_role_key()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (SELECT secret FROM public.cron_secrets WHERE name = 'service_role_key');
END;
$$;

-- ============================================
-- 4. Create new cron job with hardcoded URL
-- ============================================
SELECT cron.schedule(
  'process-fcm-notifications',
  '*/1 * * * *',  -- Every 1 minute
  $$
    SELECT net.http_post(
      url := 'https://vjpaolkqlumpyuxxmmvr.supabase.co/functions/v1/process_queue',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || get_service_role_key()
      ),
      body := '{}'::jsonb
    );
  $$
);

-- ============================================
-- MANUAL STEP: Insert service role key
-- ============================================
-- Run this in SQL Editor (replace with your actual service_role key):
-- 
-- INSERT INTO vault.secrets (name, secret)
-- VALUES ('service_role_key', 'YOUR_SERVICE_ROLE_KEY')
-- ON CONFLICT (name) DO UPDATE SET secret = EXCLUDED.secret;
--

-- ============================================
-- 5. Verify cron job
-- ============================================
SELECT 
  jobid,
  jobname,
  schedule,
  active
FROM cron.job
WHERE jobname = 'process-fcm-notifications';
