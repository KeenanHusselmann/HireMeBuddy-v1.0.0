-- Optimize RLS Performance - Fix auth_rls_initplan warnings
-- Wrap auth.uid() and other auth functions in (select ...) to prevent re-evaluation per row
-- Also removes duplicate policies and duplicate indexes

-- =====================================================
-- DROP ALL EXISTING POLICIES (ONLY FOR EXISTING TABLES)
-- =====================================================

-- Drop profiles policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile (select)" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Allow profile creation during signup" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles (select)" ON profiles;

-- Drop provider_profiles policies
DROP POLICY IF EXISTS "Verified providers are viewable by everyone" ON provider_profiles;
DROP POLICY IF EXISTS "Providers can update own profile" ON provider_profiles;
DROP POLICY IF EXISTS "Users can create provider profile" ON provider_profiles;
DROP POLICY IF EXISTS "Admins can update any provider profile" ON provider_profiles;
DROP POLICY IF EXISTS "Admins can view all provider profiles" ON provider_profiles;
DROP POLICY IF EXISTS "Admins can insert provider profiles" ON provider_profiles;
DROP POLICY IF EXISTS "Admins can delete provider profiles" ON provider_profiles;

-- Drop service_categories policies
DROP POLICY IF EXISTS "Active service categories viewable by all" ON service_categories;
DROP POLICY IF EXISTS "Service categories are viewable by everyone" ON service_categories;
DROP POLICY IF EXISTS "Users can view active categories" ON service_categories;
DROP POLICY IF EXISTS "Admins can manage service categories" ON service_categories;
DROP POLICY IF EXISTS "Authenticated users can create categories" ON service_categories;
DROP POLICY IF EXISTS "Admins can modify categories" ON service_categories;
DROP POLICY IF EXISTS "Admins can delete categories" ON service_categories;

-- Drop provider_services policies
DROP POLICY IF EXISTS "Provider services viewable by all" ON provider_services;
DROP POLICY IF EXISTS "Providers can manage own services" ON provider_services;

-- Drop bookings policies
DROP POLICY IF EXISTS "Clients can view own bookings" ON bookings;
DROP POLICY IF EXISTS "Providers can view assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Clients can create bookings" ON bookings;
DROP POLICY IF EXISTS "Clients can update own bookings" ON bookings;
DROP POLICY IF EXISTS "Clients can update pending bookings" ON bookings;
DROP POLICY IF EXISTS "Providers can update assigned bookings" ON bookings;

-- Drop reviews policies
DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON reviews;
DROP POLICY IF EXISTS "Clients can create reviews" ON reviews;
DROP POLICY IF EXISTS "Users can create reviews for their completed bookings" ON reviews;
DROP POLICY IF EXISTS "Clients can update their reviews" ON reviews;
DROP POLICY IF EXISTS "Admins can delete reviews" ON reviews;

-- Drop messages policies
DROP POLICY IF EXISTS "Users can view their messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update received messages" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;

-- Drop notifications policies
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;

-- Drop payments policies
DROP POLICY IF EXISTS "Users can view their payments" ON payments;
DROP POLICY IF EXISTS "Admins can view all payments" ON payments;
DROP POLICY IF EXISTS "System can create payments" ON payments;

-- Drop admin_actions policies
DROP POLICY IF EXISTS "Admins can view admin actions" ON admin_actions;
DROP POLICY IF EXISTS "Admins can create admin actions" ON admin_actions;

-- Drop device_tokens policies (if table exists)
DROP POLICY IF EXISTS "Users can manage their own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can read own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can insert own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can update own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can delete own device tokens" ON device_tokens;

-- Drop chat_messages policies (if table exists)
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert messages they send" ON chat_messages;
DROP POLICY IF EXISTS "Users can update messages they received (mark as read)" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_select_policy" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert_policy" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_update_policy" ON chat_messages;

-- =====================================================
-- OPTIMIZED PROFILES POLICIES
-- =====================================================

-- Everyone can read profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK ((select auth.uid()) = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING ((select auth.uid()) = id);

-- Admins can update any profile
CREATE POLICY "Admins can update any profile"
  ON profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- =====================================================
-- OPTIMIZED PROVIDER PROFILES POLICIES
-- =====================================================

-- Everyone can view verified providers, users can see their own profile
CREATE POLICY "Verified providers are viewable by everyone"
  ON provider_profiles FOR SELECT
  USING (is_verified = true OR id = (select auth.uid()));

-- Providers can update their own profile
CREATE POLICY "Providers can update own profile"
  ON provider_profiles FOR UPDATE
  USING ((select auth.uid()) = id);

-- Users can insert their provider profile
CREATE POLICY "Users can create provider profile"
  ON provider_profiles FOR INSERT
  WITH CHECK ((select auth.uid()) = id);

-- Admins can manage provider profiles
CREATE POLICY "Admins can manage provider profiles"
  ON provider_profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- =====================================================
-- OPTIMIZED SERVICE CATEGORIES POLICIES
-- =====================================================

-- Everyone can read service categories
CREATE POLICY "Active service categories viewable by all"
  ON service_categories FOR SELECT
  USING (true);

-- Admins can manage service categories (insert, update, delete)
CREATE POLICY "Admins can manage service categories"
  ON service_categories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- =====================================================
-- OPTIMIZED PROVIDER SERVICES POLICIES
-- =====================================================

-- Everyone can view provider services
CREATE POLICY "Provider services viewable by all"
  ON provider_services FOR SELECT
  USING (true);

-- Providers can manage their own services
CREATE POLICY "Providers can manage own services"
  ON provider_services FOR ALL
  USING ((select auth.uid()) = provider_id);

-- =====================================================
-- OPTIMIZED BOOKINGS POLICIES
-- =====================================================

-- Clients can view their own bookings
CREATE POLICY "Clients can view own bookings"
  ON bookings FOR SELECT
  USING ((select auth.uid()) = client_id);

-- Providers can view their assigned bookings
CREATE POLICY "Providers can view assigned bookings"
  ON bookings FOR SELECT
  USING ((select auth.uid()) = provider_id);

-- Admins can view all bookings
CREATE POLICY "Admins can view all bookings"
  ON bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- Clients can create bookings
CREATE POLICY "Clients can create bookings"
  ON bookings FOR INSERT
  WITH CHECK ((select auth.uid()) = client_id);

-- Clients can update their own bookings
CREATE POLICY "Clients can update own bookings"
  ON bookings FOR UPDATE
  USING ((select auth.uid()) = client_id);

-- Providers can update their assigned bookings
CREATE POLICY "Providers can update assigned bookings"
  ON bookings FOR UPDATE
  USING ((select auth.uid()) = provider_id);

-- =====================================================
-- OPTIMIZED REVIEWS POLICIES
-- =====================================================

-- Everyone can read reviews
CREATE POLICY "Reviews are viewable by everyone"
  ON reviews FOR SELECT
  USING (true);

-- Clients can create reviews for their completed bookings
CREATE POLICY "Clients can create reviews"
  ON reviews FOR INSERT
  WITH CHECK (
    (select auth.uid()) = client_id
    AND EXISTS (
      SELECT 1 FROM bookings
      WHERE id = booking_id
      AND client_id = (select auth.uid())
      AND status = 'completed'
    )
  );

-- Clients can update their own reviews
CREATE POLICY "Clients can update their reviews"
  ON reviews FOR UPDATE
  USING ((select auth.uid()) = client_id);

-- Admins can delete reviews
CREATE POLICY "Admins can delete reviews"
  ON reviews FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- =====================================================
-- OPTIMIZED MESSAGES POLICIES
-- =====================================================

-- Users can view messages they sent or received
CREATE POLICY "Users can view their messages"
  ON messages FOR SELECT
  USING ((select auth.uid()) = sender_id OR (select auth.uid()) = receiver_id);

-- Users can send messages
CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    (select auth.uid()) = sender_id
    AND EXISTS (
      SELECT 1 FROM bookings
      WHERE id = booking_id
      AND (client_id = (select auth.uid()) OR provider_id = (select auth.uid()))
    )
  );

-- Users can update messages they received (mark as read)
CREATE POLICY "Users can update received messages"
  ON messages FOR UPDATE
  USING ((select auth.uid()) = receiver_id);

-- =====================================================
-- OPTIMIZED NOTIFICATIONS POLICIES
-- =====================================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING ((select auth.uid()) = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING ((select auth.uid()) = user_id);

-- System can create notifications for any user
CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- OPTIMIZED PAYMENTS POLICIES
-- =====================================================

-- Users can view payments for their bookings
CREATE POLICY "Users can view their payments"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE id = booking_id
      AND (client_id = (select auth.uid()) OR provider_id = (select auth.uid()))
    )
  );

-- Admins can view all payments
CREATE POLICY "Admins can view all payments"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- System can create payments
CREATE POLICY "System can create payments"
  ON payments FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- OPTIMIZED ADMIN ACTIONS POLICIES
-- =====================================================

-- Only admins can view admin actions
CREATE POLICY "Admins can view admin actions"
  ON admin_actions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- Only admins can create admin actions
CREATE POLICY "Admins can create admin actions"
  ON admin_actions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- =====================================================
-- OPTIMIZED DEVICE TOKENS POLICIES (IF TABLE EXISTS)
-- =====================================================

-- Users can read their own device tokens
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_tokens') THEN
    CREATE POLICY "Users can read own device tokens"
      ON device_tokens FOR SELECT
      USING ((select auth.uid()) = user_id);

    CREATE POLICY "Users can insert own device tokens"
      ON device_tokens FOR INSERT
      WITH CHECK ((select auth.uid()) = user_id);

    CREATE POLICY "Users can update own device tokens"
      ON device_tokens FOR UPDATE
      USING ((select auth.uid()) = user_id);

    CREATE POLICY "Users can delete own device tokens"
      ON device_tokens FOR DELETE
      USING ((select auth.uid()) = user_id);
  END IF;
END $$;

-- =====================================================
-- OPTIMIZED CHAT MESSAGES POLICIES (IF TABLE EXISTS)
-- =====================================================

-- Users can view messages they sent or received
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chat_messages') THEN
    CREATE POLICY "Users can view messages they sent or received"
      ON chat_messages FOR SELECT
      USING ((select auth.uid()) = sender_id OR (select auth.uid()) = receiver_id);

    CREATE POLICY "Users can insert messages they send"
      ON chat_messages FOR INSERT
      WITH CHECK ((select auth.uid()) = sender_id);

    CREATE POLICY "Users can update messages they received (mark as read)"
      ON chat_messages FOR UPDATE
      USING ((select auth.uid()) = receiver_id);
  END IF;
END $$;

-- =====================================================
-- DROP DUPLICATE INDEXES
-- =====================================================

-- chat_messages duplicate indexes (if they exist)
DROP INDEX IF EXISTS idx_chat_messages_created_at;
DROP INDEX IF EXISTS idx_chat_messages_receiver;
DROP INDEX IF EXISTS idx_chat_messages_sender;

-- provider_services duplicate indexes (if they exist)
DROP INDEX IF EXISTS unique_provider_service;

-- Keep the primary indexes:
-- - chat_messages_created_at_idx
-- - chat_messages_receiver_id_idx
-- - chat_messages_sender_id_idx
-- - provider_services_provider_id_service_category_id_key

-- =====================================================
-- OPTIMIZATIONS COMPLETE!
-- =====================================================
-- All auth.uid() calls wrapped in (select auth.uid())
-- Duplicate policies removed
-- Duplicate indexes removed
