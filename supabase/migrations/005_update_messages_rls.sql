-- Update RLS policies for messages table to support optional booking_id

-- Drop existing messages policies
DROP POLICY IF EXISTS "Users can view their messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update received messages" ON messages;

-- Users can view messages they sent or received
CREATE POLICY "Users can view their messages"
  ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can send messages
-- Allow if: 1) booking_id is null (general chat), OR 2) booking_id exists and user is part of that booking
CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND (
      -- Allow general chat (no booking_id)
      booking_id IS NULL
      OR
      -- Allow if user is part of the booking
      EXISTS (
        SELECT 1 FROM bookings
        WHERE id = booking_id
        AND (client_id = auth.uid() OR provider_id = auth.uid())
      )
    )
  );

-- Users can update messages they received (mark as read)
CREATE POLICY "Users can update received messages"
  ON messages FOR UPDATE
  USING (auth.uid() = receiver_id);
