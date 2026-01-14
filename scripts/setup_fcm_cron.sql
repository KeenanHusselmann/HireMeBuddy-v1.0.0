-- Complete FCM Cron Setup Script
-- Run this in Supabase SQL Editor after migration 037

-- Step 1: Insert service role key
-- SECURITY: Replace 'YOUR_SERVICE_ROLE_KEY_HERE' with actual key from Supabase Dashboard > Settings > API
INSERT INTO public.cron_secrets (name, secret)
VALUES ('service_role_key', 'YOUR_SERVICE_ROLE_KEY_HERE')
ON CONFLICT (name) DO UPDATE SET secret = EXCLUDED.secret;

-- Step 2: Verify the function works
SELECT get_service_role_key() IS NOT NULL AS key_stored;

-- Step 3: Test the cron job query manually
SELECT net.http_post(
  url := 'https://vjpaolkqlumpyuxxmmvr.supabase.co/functions/v1/process_queue',
  headers := jsonb_build_object(
    'Authorization', 'Bearer ' || get_service_role_key()
  ),
  body := '{}'::jsonb
);

-- Step 4: Verify cron job is scheduled
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname = 'process-fcm-notifications';
