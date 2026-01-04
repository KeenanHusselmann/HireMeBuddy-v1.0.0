-- Simple check: Does ANY device token exist for this user_id?
SELECT COUNT(*) as token_count
FROM device_tokens
WHERE user_id = '2f8ece05-6b6f-494f-adce-62b138916391';

-- Show ALL device tokens (not just client)
SELECT 
  user_id,
  LEFT(token, 60) as token_preview,
  is_active,
  platform,
  updated_at
FROM device_tokens
ORDER BY updated_at DESC
LIMIT 10;

-- Check if the profile exists
SELECT id, user_id, full_name, role
FROM profiles
WHERE user_id = '2f8ece05-6b6f-494f-adce-62b138916391';
