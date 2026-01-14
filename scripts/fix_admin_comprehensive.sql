-- COMPREHENSIVE ADMIN ROLE FIX
-- Run each section and check the results

-- SECTION 1: Check what the current role value is (including any whitespace or case issues)
SELECT 
    id,
    user_id,
    email,
    role,
    length(role) as role_length,
    ascii(role) as role_ascii,
    full_name
FROM profiles
WHERE email = 'admin@hiremebuddy.app';

-- SECTION 2: Force update to lowercase 'admin' (trimming any whitespace)
UPDATE profiles 
SET role = 'admin'
WHERE email = 'admin@hiremebuddy.app'
RETURNING id, email, role, full_name;

-- SECTION 3: Verify the role is exactly 'admin'
SELECT 
    id,
    email,
    role,
    CASE 
        WHEN role = 'admin' THEN 'CORRECT ✓'
        ELSE 'INCORRECT ✗ - Role is: ' || coalesce(role, 'NULL')
    END as role_check
FROM profiles
WHERE email = 'admin@hiremebuddy.app';

-- SECTION 4: Check if the user_id matches the auth.users id
SELECT 
    p.id as profile_id,
    p.user_id,
    p.email,
    p.role,
    au.id as auth_id,
    au.email as auth_email,
    CASE 
        WHEN p.id = au.id AND p.user_id = au.id THEN 'IDs MATCH ✓'
        ELSE 'ID MISMATCH ✗'
    END as id_check
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.email = 'admin@hiremebuddy.app';
