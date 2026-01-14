-- Configure FCM Cron Job Database Settings
-- This sets up the required database parameters for the cron job to work

-- ============================================
-- 1. Enable required extensions
-- ============================================
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ============================================
-- 2. Set Supabase URL and Service Role Key
-- ============================================
-- Set your Supabase project URL
ALTER DATABASE postgres 
SET app.settings.supabase_url = 'https://vjpaolkqlumpyuxxmmvr.supabase.co';

-- Note: Service role key must be set manually via SQL Editor
-- Get it from: Dashboard > Settings > API > service_role key
-- Then run: ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';

-- ============================================
-- 3. Verify settings
-- ============================================
-- Check current settings
SELECT 
  name, 
  setting 
FROM pg_settings 
WHERE name LIKE 'app.settings.%';

-- ============================================
-- 4. Check if cron job exists
-- ============================================
SELECT 
  jobid,
  jobname,
  schedule,
  active
FROM cron.job
WHERE jobname = 'process-fcm-notifications';

-- ============================================
-- IMPORTANT: MANUAL STEP REQUIRED
-- ============================================
-- You must manually set the service_role_key by running this in the SQL Editor:
--
-- ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_ACTUAL_SERVICE_ROLE_KEY';
--
-- Get your service_role_key from:
-- Supabase Dashboard > Settings > API > service_role (secret)
--
