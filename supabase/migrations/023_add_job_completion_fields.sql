-- Add job completion details fields to bookings table
-- These fields store information provided by the provider when marking a job as completed

ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS completion_notes TEXT,
ADD COLUMN IF NOT EXISTS work_completed TEXT,
ADD COLUMN IF NOT EXISTS issues_encountered TEXT,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Add comment for documentation
COMMENT ON COLUMN bookings.completion_notes IS 'General notes from provider upon job completion';
COMMENT ON COLUMN bookings.work_completed IS 'Details of work that was completed';
COMMENT ON COLUMN bookings.issues_encountered IS 'Any issues or delays encountered during the job';
COMMENT ON COLUMN bookings.completed_at IS 'Timestamp when the job was marked as completed';
