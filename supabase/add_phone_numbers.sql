-- Add phone numbers to existing client profiles
-- Replace with actual phone numbers for your clients

-- Example: Update specific clients by their email or name
-- Uncomment and modify these examples with real phone numbers:

-- Update Keenan Husselmann's phone
UPDATE profiles
SET phone = '+264811234567'  -- Replace with actual phone number
WHERE full_name = 'Keenan Husselmann'
  AND email LIKE 'keenan.husselmann%';

-- Update Kelly's phone
UPDATE profiles
SET phone = '+264817654321'  -- Replace with actual phone number
WHERE full_name = 'Kelly'
  AND email LIKE 'requellehusselmann%';

-- Verify the updates
SELECT 
  id,
  full_name,
  email,
  phone,
  created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;
