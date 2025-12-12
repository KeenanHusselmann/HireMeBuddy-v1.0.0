-- Update phone number for existing user
-- Replace the email and phone number below

UPDATE profiles 
SET contact_number = '0812226478'  -- Replace with actual phone number
WHERE full_name = 'Tester';  -- Or use: WHERE user_id = 'user-id-here'

-- Verify the update
SELECT id, full_name, contact_number, role FROM profiles WHERE full_name = 'Tester';
