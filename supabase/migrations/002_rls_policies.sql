-- HireMeBuddy Row Level Security Policies
-- Run this after 001_initial_schema.sql

-- =====================================================
-- DROP EXISTING POLICIES
-- =====================================================

-- Drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;

DROP POLICY IF EXISTS "Verified providers are viewable by everyone" ON provider_profiles;
DROP POLICY IF EXISTS "Providers can update own profile" ON provider_profiles;
DROP POLICY IF EXISTS "Users can create provider profile" ON provider_profiles;
DROP POLICY IF EXISTS "Admins can update any provider profile" ON provider_profiles;

DROP POLICY IF EXISTS "Active service categories viewable by all" ON service_categories;
DROP POLICY IF EXISTS "Admins can manage service categories" ON service_categories;

DROP POLICY IF EXISTS "Provider services viewable by all" ON provider_services;
DROP POLICY IF EXISTS "Providers can manage own services" ON provider_services;

DROP POLICY IF EXISTS "Clients can view own bookings" ON bookings;
DROP POLICY IF EXISTS "Providers can view assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Clients can create bookings" ON bookings;
DROP POLICY IF EXISTS "Clients can update pending bookings" ON bookings;
DROP POLICY IF EXISTS "Providers can update assigned bookings" ON bookings;

DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON reviews;
DROP POLICY IF EXISTS "Clients can create reviews" ON reviews;
DROP POLICY IF EXISTS "Admins can delete reviews" ON reviews;

DROP POLICY IF EXISTS "Users can view their messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update received messages" ON messages;

DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;

DROP POLICY IF EXISTS "Users can view their payments" ON payments;
DROP POLICY IF EXISTS "Admins can view all payments" ON payments;
DROP POLICY IF EXISTS "System can create payments" ON payments;

DROP POLICY IF EXISTS "Admins can view admin actions" ON admin_actions;
DROP POLICY IF EXISTS "Admins can create admin actions" ON admin_actions;

-- =====================================================
-- PROFILES POLICIES
-- =====================================================

-- Everyone can read profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Admins can update any profile
CREATE POLICY "Admins can update any profile"
  ON profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- PROVIDER PROFILES POLICIES
-- =====================================================

-- Everyone can view verified providers
CREATE POLICY "Verified providers are viewable by everyone"
  ON provider_profiles FOR SELECT
  USING (is_verified = true OR id = auth.uid());

-- Providers can update their own profile
CREATE POLICY "Providers can update own profile"
  ON provider_profiles FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their provider profile
CREATE POLICY "Users can create provider profile"
  ON provider_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Admins can update any provider profile
CREATE POLICY "Admins can update any provider profile"
  ON provider_profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- SERVICE CATEGORIES POLICIES
-- =====================================================

-- Check if service_categories table has required columns before creating policies
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='service_categories' AND column_name='is_active') THEN
    -- Everyone can read active service categories
    CREATE POLICY "Active service categories viewable by all"
      ON service_categories FOR SELECT
      USING (is_active = true);
  ELSE
    -- Fallback: Everyone can read all service categories
    CREATE POLICY "Active service categories viewable by all"
      ON service_categories FOR SELECT
      USING (true);
  END IF;

  -- Only admins can insert/update/delete service categories
  CREATE POLICY "Admins can manage service categories"
    ON service_categories FOR ALL
    USING (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
      )
    );
END $$;

-- =====================================================
-- PROVIDER SERVICES POLICIES
-- =====================================================

-- Check if provider_services table exists with required columns
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='provider_services' AND column_name='provider_id') THEN
    -- Everyone can view provider services
    CREATE POLICY "Provider services viewable by all"
      ON provider_services FOR SELECT
      USING (true);

    -- Providers can manage their own services
    CREATE POLICY "Providers can manage own services"
      ON provider_services FOR ALL
      USING (auth.uid() = provider_id);
  END IF;
END $$;

-- =====================================================
-- BOOKINGS POLICIES
-- =====================================================

-- Check if bookings table exists with required columns
DO $$ 
BEGIN
  -- Clients can view their own bookings
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='client_id') THEN
    CREATE POLICY "Clients can view own bookings"
      ON bookings FOR SELECT
      USING (auth.uid() = client_id);

    -- Clients can create bookings
    CREATE POLICY "Clients can create bookings"
      ON bookings FOR INSERT
      WITH CHECK (auth.uid() = client_id);
  END IF;

  -- Providers can view their assigned bookings
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='provider_id') THEN
    CREATE POLICY "Providers can view assigned bookings"
      ON bookings FOR SELECT
      USING (auth.uid() = provider_id);

    -- Providers can update their assigned bookings
    CREATE POLICY "Providers can update assigned bookings"
      ON bookings FOR UPDATE
      USING (auth.uid() = provider_id);
  END IF;

  -- Admins can view all bookings
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings') THEN
    CREATE POLICY "Admins can view all bookings"
      ON bookings FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = auth.uid() AND role = 'admin'
        )
      );
  END IF;

  -- Clients can update their pending bookings
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='status') 
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='client_id') THEN
    CREATE POLICY "Clients can update pending bookings"
      ON bookings FOR UPDATE
      USING (auth.uid() = client_id AND status = 'pending');
  END IF;
END $$;

-- =====================================================
-- REVIEWS POLICIES
-- =====================================================

-- Check if reviews table exists with required columns
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews') THEN
    -- Everyone can read reviews
    CREATE POLICY "Reviews are viewable by everyone"
      ON reviews FOR SELECT
      USING (true);

    -- Clients can create reviews for their completed bookings
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='client_id') THEN
      CREATE POLICY "Clients can create reviews"
        ON reviews FOR INSERT
        WITH CHECK (
          auth.uid() = client_id
          AND EXISTS (
            SELECT 1 FROM bookings
            WHERE id = booking_id
            AND client_id = auth.uid()
            AND status = 'completed'
          )
        );
    END IF;

    -- Admins can delete reviews
    CREATE POLICY "Admins can delete reviews"
      ON reviews FOR DELETE
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = auth.uid() AND role = 'admin'
        )
      );
  END IF;
END $$;

-- =====================================================
-- MESSAGES POLICIES
-- =====================================================

-- Check if messages table exists with required columns
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='sender_id') THEN
    -- Users can view messages they sent or received
    CREATE POLICY "Users can view their messages"
      ON messages FOR SELECT
      USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

    -- Users can send messages in their bookings
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='provider_id') THEN
      CREATE POLICY "Users can send messages"
        ON messages FOR INSERT
        WITH CHECK (
          auth.uid() = sender_id
          AND EXISTS (
            SELECT 1 FROM bookings
            WHERE id = booking_id
            AND (client_id = auth.uid() OR provider_id = auth.uid())
          )
        );
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='client_id') THEN
      -- Fallback: only check client_id if provider_id doesn't exist
      CREATE POLICY "Users can send messages"
        ON messages FOR INSERT
        WITH CHECK (
          auth.uid() = sender_id
          AND EXISTS (
            SELECT 1 FROM bookings
            WHERE id = booking_id
            AND client_id = auth.uid()
          )
        );
    ELSE
      -- Fallback: allow sending if user is the sender
      CREATE POLICY "Users can send messages"
        ON messages FOR INSERT
        WITH CHECK (auth.uid() = sender_id);
    END IF;

    -- Users can update messages they received (mark as read)
    CREATE POLICY "Users can update received messages"
      ON messages FOR UPDATE
      USING (auth.uid() = receiver_id);
  END IF;
END $$;

-- =====================================================
-- NOTIFICATIONS POLICIES
-- =====================================================

-- Check if notifications table exists with required columns
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='user_id') THEN
    -- Users can view their own notifications
    CREATE POLICY "Users can view own notifications"
      ON notifications FOR SELECT
      USING (auth.uid() = user_id);

    -- Users can update their own notifications (mark as read)
    CREATE POLICY "Users can update own notifications"
      ON notifications FOR UPDATE
      USING (auth.uid() = user_id);

    -- System can create notifications for any user
    CREATE POLICY "System can create notifications"
      ON notifications FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

-- =====================================================
-- PAYMENTS POLICIES
-- =====================================================

-- Check if payments table exists with required columns
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='payments' AND column_name='booking_id') THEN
    -- Users can view payments for their bookings
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='provider_id') THEN
      CREATE POLICY "Users can view their payments"
        ON payments FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM bookings
            WHERE id = booking_id
            AND (client_id = auth.uid() OR provider_id = auth.uid())
          )
        );
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='client_id') THEN
      -- Fallback: only check client_id if provider_id doesn't exist
      CREATE POLICY "Users can view their payments"
        ON payments FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM bookings
            WHERE id = booking_id
            AND client_id = auth.uid()
          )
        );
    END IF;

    -- Admins can view all payments
    CREATE POLICY "Admins can view all payments"
      ON payments FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = auth.uid() AND role = 'admin'
        )
      );

    -- System can create payments
    CREATE POLICY "System can create payments"
      ON payments FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

-- =====================================================
-- ADMIN ACTIONS POLICIES
-- =====================================================

-- Check if admin_actions table exists with required columns
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='admin_actions' AND column_name='admin_id') THEN
    -- Only admins can view admin actions
    CREATE POLICY "Admins can view admin actions"
      ON admin_actions FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = auth.uid() AND role = 'admin'
        )
      );

    -- Only admins can create admin actions
    CREATE POLICY "Admins can create admin actions"
      ON admin_actions FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = auth.uid() AND role = 'admin'
        )
      );
  END IF;
END $$;

-- =====================================================
-- RLS Policies complete!
-- =====================================================
