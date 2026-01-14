-- Drop the broken old notification trigger and function
DROP TRIGGER IF EXISTS message_notification_trigger ON messages;
DROP TRIGGER IF EXISTS create_message_notification_trigger ON messages;
DROP TRIGGER IF EXISTS trigger_create_message_notification ON messages;
DROP FUNCTION IF EXISTS create_message_notification() CASCADE;
