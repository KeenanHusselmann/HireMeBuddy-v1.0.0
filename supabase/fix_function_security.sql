-- Fix function search_path security warnings
-- Run this in Supabase SQL Editor

-- Fix: update_updated_at_column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- Fix: update_provider_rating
CREATE OR REPLACE FUNCTION update_provider_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE provider_profiles
  SET rating_average = (
    SELECT COALESCE(AVG(rating), 0)
    FROM reviews
    WHERE provider_id = NEW.provider_id
  )
  WHERE id = NEW.provider_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- Fix: create_profile_on_signup
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, role, full_name, phone)
  VALUES (
    NEW.id,
    'client',
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'phone', NULL)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- Fix: update_provider_total_jobs
CREATE OR REPLACE FUNCTION update_provider_total_jobs()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE provider_profiles
  SET completed_jobs_count = (
    SELECT COUNT(*)
    FROM bookings
    WHERE provider_id = NEW.provider_id
      AND status = 'completed'
  )
  WHERE id = NEW.provider_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- Fix: create_admin_notification (if exists)
CREATE OR REPLACE FUNCTION create_admin_notification(
  p_title TEXT,
  p_message TEXT,
  p_type TEXT DEFAULT 'system',
  p_priority TEXT DEFAULT 'medium'
)
RETURNS UUID AS $$
DECLARE
  admin_id UUID;
  notification_id UUID;
BEGIN
  -- Get first admin user
  SELECT id INTO admin_id
  FROM profiles
  WHERE role = 'admin'
  LIMIT 1;

  IF admin_id IS NULL THEN
    RAISE EXCEPTION 'No admin user found';
  END IF;

  -- Create notification
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (
    admin_id,
    p_type::notification_type,
    p_title,
    p_message,
    jsonb_build_object('priority', p_priority)
  )
  RETURNING id INTO notification_id;

  RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Verify fixes
SELECT 
  routine_schema,
  routine_name,
  specific_name,
  CASE 
    WHEN prosecdef THEN 'SECURITY DEFINER'
    ELSE 'SECURITY INVOKER'
  END as security_type,
  proconfig as search_path_set
FROM information_schema.routines
JOIN pg_proc ON pg_proc.proname = routine_name
WHERE routine_schema = 'public'
  AND routine_name IN (
    'update_updated_at_column',
    'update_provider_rating',
    'create_profile_on_signup',
    'update_provider_total_jobs',
    'create_admin_notification'
  )
ORDER BY routine_name;
