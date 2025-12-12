-- TEMPORARY FIX: Disable RLS on profiles table
-- WARNING: Only use this for testing! Re-enable RLS before production

-- Disable RLS (allows all operations without policies)
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- To re-enable later, run:
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
