-- Drop the broken trigger and function with CASCADE
DROP FUNCTION IF EXISTS update_token_last_used() CASCADE;

-- Try the insert again
INSERT INTO notification_queue (recipient_id, message_payload, processed)
VALUES (
  'ecdd05f3-99e6-4a38-bfdd-4bdfa077bc7b'::uuid,
  jsonb_build_object(
    'title', 'After Trigger Fix',
    'body', 'Should work now',
    'type', 'test',
    'data', '{}'::jsonb,
    'tokens', ARRAY['token1', 'token2', 'token3']
  ),
  false
);

-- Verify
SELECT 
  id,
  message_payload->>'title' as title,
  jsonb_array_length(message_payload->'tokens') as token_count,
  created_at
FROM notification_queue
ORDER BY created_at DESC
LIMIT 1;
