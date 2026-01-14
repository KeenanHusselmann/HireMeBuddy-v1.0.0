-- Check if pg_cron extension is enabled
SELECT * FROM pg_extension WHERE extname = 'pg_cron';

-- Check if cron job exists
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname = 'process-fcm-notifications'
  OR jobname LIKE '%fcm%'
  OR jobname LIKE '%notification%';

-- Check recent cron job runs
SELECT 
  jobid,
  runid,
  job_pid,
  database,
  username,
  command,
  status,
  return_message,
  start_time,
  end_time
FROM cron.job_run_details
WHERE jobid IN (
  SELECT jobid FROM cron.job 
  WHERE jobname = 'process-fcm-notifications'
)
ORDER BY start_time DESC
LIMIT 10;

-- Check if cron_secrets table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'cron_secrets'
) AS cron_secrets_exists;

-- Check if service role key is stored
SELECT 
  name,
  created_at,
  LENGTH(secret) as secret_length
FROM public.cron_secrets
WHERE name = 'service_role_key';
