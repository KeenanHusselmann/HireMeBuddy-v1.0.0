-- Create admin profile for admin@hiremebuddy.com
-- This fixes the RLS policy issue by ensuring the admin user exists in profiles table

-- First, get the user ID from auth.users
DO $$
DECLARE
  admin_user_id UUID;
BEGIN
  -- Get the user ID for admin@hiremebuddy.com
  SELECT id INTO admin_user_id
  FROM auth.users
  WHERE email = 'admin@hiremebuddy.com';

  -- If user exists, create/update their profile
  IF admin_user_id IS NOT NULL THEN
    INSERT INTO profiles (id, user_id, role, full_name, email)
    VALUES (
      admin_user_id,
      admin_user_id,
      'admin',
      'Admin User',
      'admin@hiremebuddy.com'
    )
    ON CONFLICT (id) 
    DO UPDATE SET 
      role = 'admin',
      user_id = admin_user_id,
      updated_at = NOW();
    
    RAISE NOTICE 'Admin profile created/updated for user: %', admin_user_id;
  ELSE
    RAISE NOTICE 'User admin@hiremebuddy.com not found in auth.users';
  END IF;
END $$;

-- Verify the admin was created
SELECT 
  id,
  user_id,
  role,
  full_name,
  email
FROM profiles
WHERE email = 'admin@hiremebuddy.com';
