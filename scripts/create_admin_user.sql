-- Script to create or update an admin user
-- Replace the email and password with your desired credentials

-- STEP 1: First, create the user in Supabase Auth dashboard or use this approach:
-- Go to: https://vjpaolkqlumpyuxxmmvr.supabase.co/project/_/auth/users
-- Click "Add user" -> "Create new user"
-- Enter email: admin@hiremebuddy.app
-- Enter password: (your secure password)
-- Click "Create user"

-- STEP 2: After creating the auth user, get the user ID and update their profile role:
-- Run this query, replacing 'admin@hiremebuddy.app' with the email you used:

UPDATE profiles 
SET 
    role = 'admin',
    full_name = 'Admin User',
    first_name = 'Admin',
    last_name = 'User'
WHERE id = (
    SELECT id 
    FROM auth.users 
    WHERE email = 'admin@hiremebuddy.app'
    LIMIT 1
);

-- STEP 3: Verify the admin user was created:
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    au.email as auth_email
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'admin';

-- ALTERNATIVE: If you want to promote an existing user to admin:
-- UPDATE profiles SET role = 'admin' WHERE email = 'your-existing-email@example.com';

-- RESET PASSWORD (if you forgot the password):
-- Go to: https://vjpaolkqlumpyuxxmmvr.supabase.co/project/_/auth/users
-- Find the user, click the three dots (...) menu
-- Select "Reset password via email" or "Send magic link"
