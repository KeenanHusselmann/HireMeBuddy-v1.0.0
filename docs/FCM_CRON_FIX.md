# FCM Push Notifications - Cron Job Configuration

## Issue: Push notifications not working after Firebase key rotation

The cron job that processes the notification queue needs database configuration to work.

## Quick Fix: Run these SQL commands in Supabase SQL Editor

Go to: https://supabase.com/dashboard/project/vjpaolkqlumpyuxxmmvr/sql/new

### Step 1: Enable required extensions
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
```

### Step 2: Get your service role key
1. Go to: https://supabase.com/dashboard/project/vjpaolkqlumpyuxxmmvr/settings/api
2. Copy the **service_role** key (click "Reveal" if hidden)

### Step 3: Configure database settings
Replace `YOUR_SERVICE_ROLE_KEY` with the actual key from Step 2:

```sql
-- Set Supabase URL
ALTER DATABASE postgres 
SET app.settings.supabase_url = 'https://vjpaolkqlumpyuxxmmvr.supabase.co';

-- Set service role key (replace with your actual key)
ALTER DATABASE postgres 
SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
```

### Step 4: Verify configuration
```sql
-- Check settings
SELECT name, setting 
FROM pg_settings 
WHERE name LIKE 'app.settings.%';
```

You should see:
- `app.settings.supabase_url` = `https://vjpaolkqlumpyuxxmmvr.supabase.co`
- `app.settings.service_role_key` = `eyJ...` (your key)

### Step 5: Check cron job status
```sql
-- Verify cron job is active
SELECT 
  jobid,
  jobname,
  schedule,
  command,
  active
FROM cron.job
WHERE jobname = 'process-fcm-notifications';
```

Should show:
- `active` = `true`
- `schedule` = `*/1 * * * *` (every minute)

### Step 6: Test manually (optional)
```sql
-- Manually trigger the Edge Function to test
SELECT net.http_post(
  url := 'https://vjpaolkqlumpyuxxmmvr.supabase.co/functions/v1/process_queue',
  headers := jsonb_build_object(
    'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
  ),
  body := '{}'::jsonb
);
```

### Step 7: Check for pending notifications
```sql
-- See if there are any notifications waiting to be processed
SELECT 
  id,
  recipient_id,
  type,
  created_at,
  processed_at,
  status
FROM notification_queue
WHERE processed_at IS NULL
ORDER BY created_at DESC
LIMIT 10;
```

## After Configuration

1. Wait 1 minute for the cron job to run
2. Send a test message in the app
3. Check if notification arrives within 1-2 minutes

## If Still Not Working

Check Edge Function logs for errors:
https://supabase.com/dashboard/project/vjpaolkqlumpyuxxmmvr/functions/process_queue

Look for:
- "SERVICE_ACCOUNT_JSON not set" errors
- "FCM send failed" errors
- Any authentication errors
