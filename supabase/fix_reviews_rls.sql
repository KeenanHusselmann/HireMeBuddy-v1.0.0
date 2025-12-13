-- Fix reviews RLS policies to use reviewer_id instead of client_id

-- Drop existing policies
DROP POLICY IF EXISTS "Clients can create reviews" ON reviews;
DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON reviews;
DROP POLICY IF EXISTS "Clients can update their reviews" ON reviews;
DROP POLICY IF EXISTS "Admins can delete reviews" ON reviews;

-- Everyone can read reviews
CREATE POLICY "Reviews are viewable by everyone"
  ON reviews FOR SELECT
  USING (true);

-- Clients can create/update reviews for their completed bookings
CREATE POLICY "Clients can create reviews"
  ON reviews FOR INSERT
  WITH CHECK (
    auth.uid() = reviewer_id
    AND EXISTS (
      SELECT 1 FROM bookings
      WHERE id = booking_id
      AND client_id = auth.uid()
      AND status IN ('completed', 'paid')
    )
  );

-- Clients can update their own reviews
CREATE POLICY "Clients can update their reviews"
  ON reviews FOR UPDATE
  USING (auth.uid() = reviewer_id)
  WITH CHECK (auth.uid() = reviewer_id);

-- Admins can delete reviews
CREATE POLICY "Admins can delete reviews"
  ON reviews FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
