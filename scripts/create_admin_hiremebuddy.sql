-- Step 1: Insert the admin user into profiles table
-- Note: You must first create the auth user via Supabase Dashboard or API

-- After creating the auth user in Supabase Dashboard (https://vjpaolkqlumpyuxxmmvr.supabase.co/project/_/auth/users)
-- with email: admin@hiremebuddy.app and password: ;&k3;QNx8-k?RT_
-- Run this query to set up the admin profile:

INSERT INTO profiles (id, user_id, email, role, full_name, first_name, last_name, phone)
SELECT 
    au.id,
    au.id,
    au.email,
    'admin',
    'Admin User',
    'Admin',
    'User',
    '+264000000000'
FROM auth.users au
WHERE au.email = 'admin@hiremebuddy.app'
ON CONFLICT (id) 
DO UPDATE SET 
    user_id = EXCLUDED.user_id,
    role = 'admin',
    full_name = 'Admin User',
    first_name = 'Admin',
    last_name = 'User';

-- Verify the admin user was created
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.created_at
FROM profiles p
WHERE p.email = 'admin@hiremebuddy.app';
