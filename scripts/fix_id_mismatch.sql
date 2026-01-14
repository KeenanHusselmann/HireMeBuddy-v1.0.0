-- Fix the ID mismatch for admin@hiremebuddy.app
-- We need to delete the old profile and create a new one with the correct ID

-- Step 1: Delete the old profile with the wrong ID
DELETE FROM profiles 
WHERE email = 'admin@hiremebuddy.app' 
AND id != '0c47797c-bb40-45b2-bd5f-70e4cb0c97ce';

-- Step 2: Insert the correct profile with matching ID
INSERT INTO profiles (id, user_id, email, role, full_name, first_name, last_name, phone)
VALUES (
    '0c47797c-bb40-45b2-bd5f-70e4cb0c97ce',
    '0c47797c-bb40-45b2-bd5f-70e4cb0c97ce',
    'admin@hiremebuddy.app',
    'admin',
    'Admin User',
    'Admin',
    'User',
    '+264000000000'
)
ON CONFLICT (id) 
DO UPDATE SET 
    user_id = EXCLUDED.user_id,
    role = 'admin',
    full_name = 'Admin User',
    first_name = 'Admin',
    last_name = 'User',
    email = EXCLUDED.email;

-- Step 3: Verify the fix
SELECT 
    p.id as profile_id,
    p.user_id as profile_user_id,
    p.email as profile_email,
    p.role,
    au.id as auth_id,
    au.email as auth_email,
    CASE 
        WHEN p.id = au.id AND p.user_id = au.id THEN 'FIXED ✓'
        ELSE 'STILL BROKEN ✗'
    END as status
FROM profiles p
JOIN auth.users au ON p.id = au.id
WHERE p.email = 'admin@hiremebuddy.app';
