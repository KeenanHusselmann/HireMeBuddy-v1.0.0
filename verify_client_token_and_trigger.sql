-- 1. Check if client has saved their FCM token
SELECT 
  dt.user_id,
  LEFT(dt.token, 60) as token_preview,
  dt.is_active,
  dt.platform,
  dt.updated_at,
  p.full_name,
  p.role
FROM device_tokens dt
LEFT JOIN profiles p ON p.user_id = dt.user_id
WHERE dt.user_id = '2f8ece05-6b6f-494f-adce-62b138916391'  -- client_id from bookings
ORDER BY dt.updated_at DESC;

-- 2. Check the booking status change trigger function to see who it sends to
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'notify_booking_status_change';
