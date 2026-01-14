-- Check if auth.users entry exists and matches the profile
SELECT 
    p.id as profile_id,
    p.user_id as profile_user_id,
    p.email as profile_email,
    p.role,
    au.id as auth_id,
    au.email as auth_email,
    au.email_confirmed_at,
    au.created_at as auth_created,
    CASE 
        WHEN au.id IS NULL THEN 'NO AUTH USER ✗'
        WHEN p.id != au.id THEN 'ID MISMATCH ✗'
        WHEN p.user_id != au.id THEN 'USER_ID MISMATCH ✗'
        WHEN au.email_confirmed_at IS NULL THEN 'EMAIL NOT CONFIRMED ✗'
        ELSE 'ALL GOOD ✓'
    END as status
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.email = 'admin@hiremebuddy.app';

-- If auth user doesn't exist or IDs don't match, we need to fix it
-- Check what auth users exist with similar emails
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users
WHERE email LIKE '%hiremebuddy%'
ORDER BY created_at DESC;
