-- MANUAL TEST: Insert a profile for your current logged-in user
-- Run this in Supabase SQL Editor

-- First, check what users exist in auth.users
SELECT id, email, raw_user_meta_data->>'full_name' as full_name 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- Copy the user ID from above and use it below
-- Replace 'YOUR_USER_ID_HERE' with the actual UUID

-- Insert profile manually (replace the ID and name)
INSERT INTO profiles (id, full_name, role, phone, created_at, updated_at)
VALUES (
  'YOUR_USER_ID_HERE',  -- Replace with actual user ID from above query
  'Test Provider',       -- Replace with actual name
  'provider',
  NULL,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE 
SET 
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  updated_at = NOW();

-- Verify it was created
SELECT * FROM profiles ORDER BY created_at DESC LIMIT 5;
