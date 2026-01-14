-- Populate email addresses from auth.users to profiles table

-- Update profiles.email with the email from auth.users
UPDATE profiles
SET email = auth.users.email
FROM auth.users
WHERE profiles.id = auth.users.id
  AND profiles.email IS NULL;

-- Verify the update
SELECT 
  p.id,
  p.full_name,
  p.email,
  p.phone,
  au.email as auth_email
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
ORDER BY p.created_at DESC
LIMIT 10;
