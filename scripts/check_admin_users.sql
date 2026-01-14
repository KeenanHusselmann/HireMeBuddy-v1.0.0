-- Check all admin users in the database
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.created_at,
    au.email as auth_email,
    au.created_at as auth_created_at,
    au.last_sign_in_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'admin'
ORDER BY p.created_at DESC;

-- Check if any users exist with admin role
SELECT COUNT(*) as admin_count FROM profiles WHERE role = 'admin';
