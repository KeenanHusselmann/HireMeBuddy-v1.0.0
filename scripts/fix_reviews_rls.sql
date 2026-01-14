-- Fix reviews table RLS policies
-- The issue: auth.uid() is the user_id, but client_id is the profile_id
-- We need to join to profiles to match them correctly

-- Drop existing policies
DROP POLICY IF EXISTS "reviews_insert_policy" ON reviews;
DROP POLICY IF EXISTS "reviews_update_policy" ON reviews;

-- Create correct INSERT policy that matches user_id to profile
CREATE POLICY "reviews_insert_policy"
  ON reviews FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = client_id
      AND p.user_id = auth.uid()
    )
  );

-- Create correct UPDATE policy
CREATE POLICY "reviews_update_policy"
  ON reviews FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = client_id
      AND p.user_id = auth.uid()
    )
  );

-- Verify the policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'reviews'
ORDER BY policyname;
