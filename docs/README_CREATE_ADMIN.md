-- Create admin user in auth.users and profiles tables
-- Run this in Supabase SQL Editor

-- Step 1: Create the admin user in auth.users (if not exists)
-- You'll need to set the password through Supabase Dashboard > Authentication > Users > Add User
-- Email: admin@hiremebuddy.com
-- Password: admin123 (or your preferred password)

-- Step 2: After creating the user in Dashboard, run this to update their profile:
-- Replace 'YOUR_ADMIN_USER_ID' with the actual UUID from auth.users

-- First check if admin user exists:
SELECT id, email FROM auth.users WHERE email = 'admin@hiremebuddy.com';

-- If the above returns a user, copy the ID and use it below:
-- UPDATE THIS with the actual user ID after creating the user in dashboard:
/*
INSERT INTO profiles (id, role, full_name, email)
VALUES (
  'PASTE_USER_ID_HERE'::uuid,
  'admin',
  'Admin User', 
  'admin@hiremebuddy.com'
)
ON CONFLICT (id)
DO UPDATE SET
  role = 'admin',
  updated_at = NOW();
*/
