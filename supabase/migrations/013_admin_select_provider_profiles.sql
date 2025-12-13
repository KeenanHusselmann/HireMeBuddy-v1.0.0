-- Add SELECT policy for admins on provider_profiles
-- This allows admins to view all provider profiles (verified and unverified)

CREATE POLICY "Admins can view all provider profiles"
  ON provider_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
