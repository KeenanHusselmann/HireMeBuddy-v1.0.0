-- =====================================================
-- FIX REVIEWS SELECT POLICY
-- =====================================================
-- The SELECT policy is incorrectly referencing 'provider_profiles' 
-- which doesn't exist. It should use 'profiles' instead.

-- 1. Check current policies
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'reviews'
ORDER BY policyname;

-- 2. Drop the broken SELECT policy
DROP POLICY IF EXISTS "reviews_select_policy" ON reviews;
DROP POLICY IF EXISTS "reviews_view_policy" ON reviews;
DROP POLICY IF EXISTS "Enable read access for users" ON reviews;
DROP POLICY IF EXISTS "Users can view reviews" ON reviews;

-- 3. Create correct SELECT policy
-- Users can view all reviews (public read access)
-- OR limit to reviews they created or reviews of their provider profile
CREATE POLICY "reviews_select_policy"
  ON reviews FOR SELECT
  USING (
    -- Public read access (anyone can see reviews)
    true
    -- OR if you want restricted access:
    -- EXISTS (
    --   SELECT 1 FROM profiles p
    --   WHERE (p.id = client_id OR p.id = provider_id)
    --   AND p.user_id = auth.uid()
    -- )
  );

-- 4. Verify all policies are correct
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  cmd,
  CASE cmd
    WHEN 'SELECT' THEN qual
    WHEN 'INSERT' THEN with_check
    WHEN 'UPDATE' THEN qual
    ELSE 'N/A'
  END as policy_definition
FROM pg_policies
WHERE tablename = 'reviews'
ORDER BY policyname;
