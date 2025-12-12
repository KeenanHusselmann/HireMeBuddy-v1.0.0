-- Fix notifications table to use 'body' instead of 'message'
DO $$
BEGIN
  -- Check if 'message' column exists and 'body' doesn't
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'notifications' 
    AND column_name = 'message'
  ) AND NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'notifications' 
    AND column_name = 'body'
  ) THEN
    -- Rename 'message' to 'body'
    ALTER TABLE notifications RENAME COLUMN message TO body;
    RAISE NOTICE 'Renamed notifications.message to notifications.body';
  ELSIF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'notifications' 
    AND column_name = 'body'
  ) THEN
    -- Add 'body' column if it doesn't exist
    ALTER TABLE notifications ADD COLUMN body TEXT NOT NULL DEFAULT '';
    RAISE NOTICE 'Added notifications.body column';
  END IF;
END $$;
