-- Create waitlist table for landing page signups
CREATE TABLE IF NOT EXISTS public.waitlist (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    phone_number TEXT,
    user_type TEXT NOT NULL CHECK (user_type IN ('client', 'provider')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'contacted', 'converted', 'rejected')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS waitlist_email_idx ON public.waitlist(email);

-- Create index on user_type for filtering
CREATE INDEX IF NOT EXISTS waitlist_user_type_idx ON public.waitlist(user_type);

-- Create index on status for filtering
CREATE INDEX IF NOT EXISTS waitlist_status_idx ON public.waitlist(status);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS waitlist_created_at_idx ON public.waitlist(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can insert (public signup form)
CREATE POLICY "Anyone can insert waitlist" ON public.waitlist
    FOR INSERT
    WITH CHECK (true);

-- Policy: Only admins can view all waitlist entries
CREATE POLICY "Admins can view all waitlist" ON public.waitlist
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Policy: Only admins can update waitlist entries
CREATE POLICY "Admins can update waitlist" ON public.waitlist
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Policy: Only admins can delete waitlist entries
CREATE POLICY "Admins can delete waitlist" ON public.waitlist
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_waitlist_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER set_waitlist_updated_at
    BEFORE UPDATE ON public.waitlist
    FOR EACH ROW
    EXECUTE FUNCTION update_waitlist_updated_at();

-- Add comment to table
COMMENT ON TABLE public.waitlist IS 'Stores landing page signups for the waiting list feature shown in admin dashboard';
