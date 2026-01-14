-- Fix the admin@hiremebuddy.app account
UPDATE profiles 
SET 
    full_name = 'Admin User',
    first_name = 'Admin',
    last_name = 'User'
WHERE email = 'admin@hiremebuddy.app';

-- Verify both admin accounts
SELECT 
    id,
    email,
    role,
    full_name,
    first_name,
    last_name
FROM profiles
WHERE email IN ('admin@hiremebuddy.app', 'admin@hiremebuddy.com')
ORDER BY email;
