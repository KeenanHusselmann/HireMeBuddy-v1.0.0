-- Fix device_tokens RLS policy to allow SECURITY DEFINER functions
-- Drop existing policies
DROP POLICY IF EXISTS "device_tokens_select_policy" ON device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_policy" ON device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_policy" ON device_tokens;
DROP POLICY IF EXISTS "device_tokens_delete_policy" ON device_tokens;

-- Create device_tokens policies with SECURITY DEFINER support
-- Allow SECURITY DEFINER functions to read all tokens (for sending notifications)
CREATE POLICY "device_tokens_select_policy"
  ON device_tokens FOR SELECT
  USING (
    auth.uid() = user_id OR  -- User can read own tokens
    current_setting('role') = 'service_role' OR  -- Service role can read all
    auth.uid() IS NULL  -- Allow SECURITY DEFINER functions
  );

CREATE POLICY "device_tokens_insert_policy"
  ON device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens_update_policy"
  ON device_tokens FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens_delete_policy"
  ON device_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- Verify the fix
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'device_tokens'
ORDER BY policyname;
