-- Create waiting list table for landing page signups
CREATE TABLE IF NOT EXISTS public.waiting_list (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('provider', 'client')),
    service_category VARCHAR(100),
    location VARCHAR(255),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    subscribed_to_updates BOOLEAN DEFAULT true,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'contacted', 'converted'))
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_waiting_list_user_type ON public.waiting_list(user_type);
CREATE INDEX IF NOT EXISTS idx_waiting_list_status ON public.waiting_list(status);
CREATE INDEX IF NOT EXISTS idx_waiting_list_created_at ON public.waiting_list(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.waiting_list ENABLE ROW LEVEL SECURITY;

-- Create policy to allow anyone to insert (sign up)
CREATE POLICY "Anyone can sign up for waiting list"
    ON public.waiting_list
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Create policy for admins to view all waiting list entries
CREATE POLICY "Admins can view all waiting list"
    ON public.waiting_list
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Create policy for admins to update waiting list entries
CREATE POLICY "Admins can update waiting list"
    ON public.waiting_list
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Add comment to table
COMMENT ON TABLE public.waiting_list IS 'Stores waiting list signups from landing page';
