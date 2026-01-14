-- Update messages table to support both booking messages and general chat
-- Make booking_id optional and add conversation_id for general chat

-- Drop the NOT NULL constraint on booking_id (if it exists)
DO $$ 
BEGIN
  ALTER TABLE messages ALTER COLUMN booking_id DROP NOT NULL;
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- Add conversation_id for general chat threads (optional)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS conversation_id UUID;

-- Rename 'message' to 'content' if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' AND column_name = 'message'
  ) THEN
    ALTER TABLE messages RENAME COLUMN message TO content;
  END IF;
END $$;

-- Add 'content' column if it doesn't exist
ALTER TABLE messages ADD COLUMN IF NOT EXISTS content TEXT NOT NULL DEFAULT '';

-- Rename 'is_read' to 'read' if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' AND column_name = 'is_read'
  ) THEN
    ALTER TABLE messages RENAME COLUMN is_read TO read;
  END IF;
END $$;

-- Add 'read' column if it doesn't exist
ALTER TABLE messages ADD COLUMN IF NOT EXISTS read BOOLEAN DEFAULT false;

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_messages_receiver_read ON messages(receiver_id, read);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);

-- Add comment
COMMENT ON TABLE messages IS 'Unified messages table for both booking-related and general chat messages';
