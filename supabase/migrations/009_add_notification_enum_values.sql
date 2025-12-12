-- Add missing enum values to notification_type
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'booking_update';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'booking_request';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'job_completed';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'payment_received';

-- Verify enum values
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'notification_type'::regtype
ORDER BY enumsortorder;
