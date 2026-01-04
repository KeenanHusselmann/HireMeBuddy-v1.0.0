-- Debug: Check the actual relationship between bookings and profiles
SELECT 
  b.id as booking_id,
  b.client_id as client_profile_id,
  b.provider_id as provider_profile_id,
  cp.user_id as client_user_id,
  pp.user_id as provider_user_id,
  cp.full_name as client_name,
  pp.full_name as provider_name
FROM bookings b
LEFT JOIN profiles cp ON cp.id = b.client_id
LEFT JOIN profiles pp ON pp.id = b.provider_id
WHERE b.id = '8731ff75-c64e-4aec-96db-be969e4f3487'  -- Latest booking
LIMIT 1;
