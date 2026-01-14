-- Migration to handle any existing 'confirmed' status in bookings table
-- This migration adds 'confirmed' temporarily to the enum, migrates data, then removes it

-- Step 1: Add 'confirmed' to the enum if it doesn't exist (for backwards compatibility)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'confirmed' 
        AND enumtypid = 'booking_status'::regtype
    ) THEN
        ALTER TYPE booking_status ADD VALUE 'confirmed';
        RAISE NOTICE 'Added confirmed to booking_status enum';
    ELSE
        RAISE NOTICE 'confirmed already exists in booking_status enum';
    END IF;
END $$;

-- Step 2: Update all existing bookings with 'confirmed' status to 'accepted'
UPDATE bookings 
SET status = 'accepted'::booking_status
WHERE status::text = 'confirmed';

-- Log the migration
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count 
    FROM bookings 
    WHERE status::text = 'accepted';
    
    RAISE NOTICE 'Migration complete. Total bookings with accepted status: %', updated_count;
END $$;

-- Note: We cannot remove 'confirmed' from the enum without recreating it
-- which would require dropping and recreating all dependent objects.
-- Instead, we'll just ensure all data uses the correct values.
-- The app code has been updated to use 'accepted' instead of 'confirmed'.
