-- Check current notifications table structure and fix it
DO $$
BEGIN
  -- Add title column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'title'
  ) THEN
    ALTER TABLE notifications ADD COLUMN title TEXT NOT NULL DEFAULT 'Notification';
    RAISE NOTICE 'Added title column to notifications';
  END IF;

  -- Add body column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'body'
  ) THEN
    ALTER TABLE notifications ADD COLUMN body TEXT NOT NULL DEFAULT '';
    RAISE NOTICE 'Added body column to notifications';
  END IF;

  -- Rename message to body if it exists and body doesn't
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'message'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'body'
  ) THEN
    ALTER TABLE notifications RENAME COLUMN message TO body;
    RAISE NOTICE 'Renamed message to body';
  END IF;

  -- Add type column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'type'
  ) THEN
    -- Create enum type if it doesn't exist
    DO $type$ 
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM ('booking_request', 'booking_update', 'payment', 'message', 'system');
      END IF;
    END $type$;
    
    ALTER TABLE notifications ADD COLUMN type notification_type DEFAULT 'system';
    RAISE NOTICE 'Added type column to notifications';
  END IF;
END $$;

-- Verify the structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;
