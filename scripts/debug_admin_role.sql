-- Check current role for admin@hiremebuddy.app
SELECT 
    id,
    user_id,
    email,
    role,
    full_name,
    created_at
FROM profiles
WHERE email = 'admin@hiremebuddy.app';

-- Update to admin role (make sure it's lowercase 'admin')
UPDATE profiles 
SET role = 'admin'
WHERE email = 'admin@hiremebuddy.app';

-- Verify the update
SELECT 
    id,
    user_id,
    email,
    role,
    full_name
FROM profiles
WHERE email = 'admin@hiremebuddy.app';

-- Also check if there are any other admin users to compare
SELECT 
    id,
    email,
    role,
    full_name
FROM profiles
WHERE role = 'admin'
LIMIT 5;
