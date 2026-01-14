-- Check the current state of profiles
SELECT id, full_name, role, email, created_at
FROM profiles
ORDER BY created_at DESC;

-- Check if there are any provider_profiles for users with role='client'
SELECT 
    p.id,
    p.full_name,
    p.role,
    pp.id as provider_profile_id,
    pp.is_verified
FROM profiles p
LEFT JOIN provider_profiles pp ON p.id = pp.id
WHERE pp.id IS NOT NULL;

-- Fix: Update role to 'provider' for users who have a provider_profile
UPDATE profiles
SET role = 'provider'
WHERE id IN (
    SELECT p.id
    FROM profiles p
    INNER JOIN provider_profiles pp ON p.id = pp.id
    WHERE p.role = 'client'
);

-- Verify the fix
SELECT 
    p.id,
    p.full_name,
    p.role,
    pp.id as has_provider_profile
FROM profiles p
LEFT JOIN provider_profiles pp ON p.id = pp.id
ORDER BY p.created_at DESC;
