-- Sync email addresses from auth.users to profiles table
-- This fixes the issue where existing profiles don't have email values

-- Update profiles table with email from auth.users
UPDATE profiles p
SET email = au.email
FROM auth.users au
WHERE p.id = au.id
AND (p.email IS NULL OR p.email = '');

-- Verify the update
SELECT 
  p.id, 
  p.full_name, 
  p.email as profile_email, 
  au.email as auth_email
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'provider'
ORDER BY p.created_at DESC;
