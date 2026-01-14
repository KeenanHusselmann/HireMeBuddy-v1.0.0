-- Update existing user to admin role
-- Use this when the user already exists in the profiles table

UPDATE profiles 
SET 
    role = 'admin',
    full_name = 'Admin User',
    first_name = 'Admin',
    last_name = 'User'
WHERE email = 'admin@hiremebuddy.app';

-- Verify the admin user was updated
SELECT 
    id,
    user_id,
    email,
    full_name,
    role,
    created_at
FROM profiles
WHERE email = 'admin@hiremebuddy.app';
