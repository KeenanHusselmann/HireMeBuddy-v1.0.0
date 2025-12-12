-- Enable Row Level Security on all tables
-- Run this in Supabase SQL Editor to fix security linter errors

-- Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Enable RLS on bookings table  
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Enable RLS on provider_profiles table
ALTER TABLE public.provider_profiles ENABLE ROW LEVEL SECURITY;

-- Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('profiles', 'bookings', 'provider_profiles')
ORDER BY tablename;

-- Check active policies
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename IN ('profiles', 'bookings', 'provider_profiles')
ORDER BY tablename, policyname;
