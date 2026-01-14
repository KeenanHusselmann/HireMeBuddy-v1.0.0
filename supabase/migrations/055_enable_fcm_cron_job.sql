-- Re-enable the cron job to process notifications every minute
-- First, remove old job if exists
DO $$
BEGIN
  PERFORM cron.unschedule('process-fcm-notifications');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END $$;

-- Create the cron job
SELECT cron.schedule(
  'process-fcm-notifications',
  '*/1 * * * *',  -- Every 1 minute
  $$
    SELECT net.http_post(
      url := 'https://vjpaolkqlumpyuxxmmvr.supabase.co/functions/v1/process_queue',
      headers := jsonb_build_object(
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjkxNjc4MSwiZXhwIjoyMDY4NDkyNzgxfQ.iuZzBILhJ05jwYQgdamdhEMECWcOt3_vUSIei3Fgyj0'
      ),
      body := '{}'::jsonb
    );
  $$
);

-- Verify it was created
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname = 'process-fcm-notifications';
