-- Check if current user is an admin
SELECT 
  id,
  role,
  full_name,
  email
FROM profiles
WHERE id = auth.uid();

-- Check all existing policies on provider_profiles
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'provider_profiles';
