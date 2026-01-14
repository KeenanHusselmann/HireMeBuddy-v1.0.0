-- Get provider count
SELECT COUNT(*) as provider_count 
FROM provider_profiles
WHERE is_verified = true;

-- Get client count (profiles with role = 'client')
SELECT COUNT(*) as client_count
FROM profiles
WHERE role = 'client';
