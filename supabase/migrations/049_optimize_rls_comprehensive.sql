-- Comprehensive RLS Performance Optimization
-- Wraps all auth.uid() calls in (select auth.uid()) to prevent per-row re-evaluation
-- Handles all existing tables with proper conditional checks

-- =====================================================
-- DROP ALL EXISTING POLICIES
-- =====================================================

-- Core tables
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
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

-- Extended tables
DROP POLICY IF EXISTS "Admins can view all notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Admins can update notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Admins can delete notifications" ON admin_notifications;

DROP POLICY IF EXISTS "Only admins can access settings" ON admin_settings;

DROP POLICY IF EXISTS "Allow admin read access" ON waiting_list;
DROP POLICY IF EXISTS "Allow admin update access" ON waiting_list;

DROP POLICY IF EXISTS "Providers can insert their own portfolio images" ON portfolio_images;
DROP POLICY IF EXISTS "Providers can update their own portfolio images" ON portfolio_images;
DROP POLICY IF EXISTS "Providers can delete their own portfolio images" ON portfolio_images;
DROP POLICY IF EXISTS "Portfolio images are viewable by everyone" ON portfolio_images;

DROP POLICY IF EXISTS "Providers can insert their own testimonials" ON testimonials;
DROP POLICY IF EXISTS "Providers can update their own testimonials" ON testimonials;
DROP POLICY IF EXISTS "Providers can delete their own testimonials" ON testimonials;
DROP POLICY IF EXISTS "Testimonials are viewable by everyone" ON testimonials;

DROP POLICY IF EXISTS "Users can view their own quote requests" ON quote_requests;
DROP POLICY IF EXISTS "Users can update their own quote requests" ON quote_requests;
DROP POLICY IF EXISTS "Clients can create quote requests" ON quote_requests;
DROP POLICY IF EXISTS "Providers can view quote requests for their services" ON quote_requests;

DROP POLICY IF EXISTS "Provider categories are viewable by everyone" ON provider_categories;
DROP POLICY IF EXISTS "Providers can manage their own categories" ON provider_categories;

DROP POLICY IF EXISTS "Service subcategories are viewable by everyone" ON service_subcategories;
DROP POLICY IF EXISTS "Authenticated users can create subcategories" ON service_subcategories;
DROP POLICY IF EXISTS "Users can update their own subcategories" ON service_subcategories;

DROP POLICY IF EXISTS "Users can read own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can insert own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can update own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can delete own device tokens" ON device_tokens;

DROP POLICY IF EXISTS "Users can view messages they sent or received" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert messages they send" ON chat_messages;
DROP POLICY IF EXISTS "Users can update messages they received (mark as read)" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_select_policy" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert_policy" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_update_policy" ON chat_messages;

DROP POLICY IF EXISTS "Authenticated users can view presence" ON user_presence;
DROP POLICY IF EXISTS "Users can manage their own presence" ON user_presence;

-- =====================================================
-- OPTIMIZED PROFILES POLICIES
-- =====================================================

CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING ((select auth.uid()) = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK ((select auth.uid()) = id);

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

CREATE POLICY "Verified providers are viewable by everyone"
  ON provider_profiles FOR SELECT
  USING (is_verified = true OR id = (select auth.uid()));

CREATE POLICY "Providers can update own profile"
  ON provider_profiles FOR UPDATE
  USING ((select auth.uid()) = id);

CREATE POLICY "Users can create provider profile"
  ON provider_profiles FOR INSERT
  WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "Admins can update any provider profile"
  ON provider_profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- =====================================================
-- OPTIMIZED SERVICE CATEGORIES POLICIES
-- =====================================================

CREATE POLICY "Active service categories viewable by all"
  ON service_categories FOR SELECT
  USING (true);

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

CREATE POLICY "Provider services viewable by all"
  ON provider_services FOR SELECT
  USING (true);

CREATE POLICY "Providers can manage own services"
  ON provider_services FOR ALL
  USING ((select auth.uid()) = provider_id);

-- =====================================================
-- OPTIMIZED BOOKINGS POLICIES
-- =====================================================

CREATE POLICY "Clients can view own bookings"
  ON bookings FOR SELECT
  USING ((select auth.uid()) = client_id);

CREATE POLICY "Providers can view assigned bookings"
  ON bookings FOR SELECT
  USING ((select auth.uid()) = provider_id);

CREATE POLICY "Admins can view all bookings"
  ON bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Clients can create bookings"
  ON bookings FOR INSERT
  WITH CHECK ((select auth.uid()) = client_id);

CREATE POLICY "Clients can update pending bookings"
  ON bookings FOR UPDATE
  USING ((select auth.uid()) = client_id AND status = 'pending');

CREATE POLICY "Providers can update assigned bookings"
  ON bookings FOR UPDATE
  USING ((select auth.uid()) = provider_id);

-- =====================================================
-- OPTIMIZED REVIEWS POLICIES
-- =====================================================

CREATE POLICY "Reviews are viewable by everyone"
  ON reviews FOR SELECT
  USING (true);

CREATE POLICY "Clients can create reviews"
  ON reviews FOR INSERT
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT client_id FROM bookings WHERE id = booking_id AND status = 'completed'
    )
  );

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

CREATE POLICY "Users can view their messages"
  ON messages FOR SELECT
  USING ((select auth.uid()) = sender_id OR (select auth.uid()) = receiver_id);

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

CREATE POLICY "Users can update received messages"
  ON messages FOR UPDATE
  USING ((select auth.uid()) = receiver_id);

-- =====================================================
-- OPTIMIZED NOTIFICATIONS POLICIES
-- =====================================================

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING ((select auth.uid()) = user_id);

CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- OPTIMIZED PAYMENTS POLICIES
-- =====================================================

CREATE POLICY "Users can view their payments"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE id = booking_id
      AND (client_id = (select auth.uid()) OR provider_id = (select auth.uid()))
    )
  );

CREATE POLICY "Admins can view all payments"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "System can create payments"
  ON payments FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- OPTIMIZED ADMIN ACTIONS POLICIES
-- =====================================================

CREATE POLICY "Admins can view admin actions"
  ON admin_actions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can create admin actions"
  ON admin_actions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- =====================================================
-- ADMIN NOTIFICATIONS (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_notifications') THEN
    EXECUTE 'CREATE POLICY "Admins can view all notifications"
      ON admin_notifications FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid()) AND role = ''admin''
        )
      )';

    EXECUTE 'CREATE POLICY "Admins can update notifications"
      ON admin_notifications FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid()) AND role = ''admin''
        )
      )';

    EXECUTE 'CREATE POLICY "Admins can delete notifications"
      ON admin_notifications FOR DELETE
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid()) AND role = ''admin''
        )
      )';
  END IF;
END $$;

-- =====================================================
-- ADMIN SETTINGS (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_settings') THEN
    EXECUTE 'CREATE POLICY "Only admins can access settings"
      ON admin_settings FOR ALL
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid()) AND role = ''admin''
        )
      )';
  END IF;
END $$;

-- =====================================================
-- WAITING LIST (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'waiting_list') THEN
    EXECUTE 'CREATE POLICY "Allow admin read access"
      ON waiting_list FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid()) AND role = ''admin''
        )
      )';

    EXECUTE 'CREATE POLICY "Allow admin update access"
      ON waiting_list FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid()) AND role = ''admin''
        )
      )';
  END IF;
END $$;

-- =====================================================
-- PORTFOLIO IMAGES (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'portfolio_images') THEN
    EXECUTE 'CREATE POLICY "Portfolio images are viewable by everyone"
      ON portfolio_images FOR SELECT
      USING (true)';

    EXECUTE 'CREATE POLICY "Providers can insert their own portfolio images"
      ON portfolio_images FOR INSERT
      WITH CHECK ((select auth.uid()) = provider_id)';

    EXECUTE 'CREATE POLICY "Providers can update their own portfolio images"
      ON portfolio_images FOR UPDATE
      USING ((select auth.uid()) = provider_id)';

    EXECUTE 'CREATE POLICY "Providers can delete their own portfolio images"
      ON portfolio_images FOR DELETE
      USING ((select auth.uid()) = provider_id)';
  END IF;
END $$;

-- =====================================================
-- TESTIMONIALS (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'testimonials') THEN
    EXECUTE 'CREATE POLICY "Testimonials are viewable by everyone"
      ON testimonials FOR SELECT
      USING (true)';

    EXECUTE 'CREATE POLICY "Providers can insert their own testimonials"
      ON testimonials FOR INSERT
      WITH CHECK ((select auth.uid()) = provider_id)';

    EXECUTE 'CREATE POLICY "Providers can update their own testimonials"
      ON testimonials FOR UPDATE
      USING ((select auth.uid()) = provider_id)';

    EXECUTE 'CREATE POLICY "Providers can delete their own testimonials"
      ON testimonials FOR DELETE
      USING ((select auth.uid()) = provider_id)';
  END IF;
END $$;

-- =====================================================
-- QUOTE REQUESTS (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'quote_requests') THEN
    EXECUTE 'CREATE POLICY "Users can view their own quote requests"
      ON quote_requests FOR SELECT
      USING ((select auth.uid()) = client_id)';

    EXECUTE 'CREATE POLICY "Users can update their own quote requests"
      ON quote_requests FOR UPDATE
      USING ((select auth.uid()) = client_id)';

    EXECUTE 'CREATE POLICY "Clients can create quote requests"
      ON quote_requests FOR INSERT
      WITH CHECK ((select auth.uid()) = client_id)';
  END IF;
END $$;

-- =====================================================
-- PROVIDER CATEGORIES (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'provider_categories') THEN
    EXECUTE 'CREATE POLICY "Provider categories are viewable by everyone"
      ON provider_categories FOR SELECT
      USING (true)';

    EXECUTE 'CREATE POLICY "Providers can manage their own categories"
      ON provider_categories FOR ALL
      USING ((select auth.uid()) = provider_id)';
  END IF;
END $$;

-- =====================================================
-- SERVICE SUBCATEGORIES (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'service_subcategories') THEN
    EXECUTE 'CREATE POLICY "Service subcategories are viewable by everyone"
      ON service_subcategories FOR SELECT
      USING (true)';

    EXECUTE 'CREATE POLICY "Authenticated users can create subcategories"
      ON service_subcategories FOR INSERT
      WITH CHECK ((select auth.uid()) IS NOT NULL)';
  END IF;
END $$;

-- =====================================================
-- DEVICE TOKENS (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'device_tokens') THEN
    EXECUTE 'CREATE POLICY "Users can read own device tokens"
      ON device_tokens FOR SELECT
      USING ((select auth.uid()) = user_id)';

    EXECUTE 'CREATE POLICY "Users can insert own device tokens"
      ON device_tokens FOR INSERT
      WITH CHECK ((select auth.uid()) = user_id)';

    EXECUTE 'CREATE POLICY "Users can update own device tokens"
      ON device_tokens FOR UPDATE
      USING ((select auth.uid()) = user_id)';

    EXECUTE 'CREATE POLICY "Users can delete own device tokens"
      ON device_tokens FOR DELETE
      USING ((select auth.uid()) = user_id)';
  END IF;
END $$;

-- =====================================================
-- CHAT MESSAGES (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chat_messages') THEN
    EXECUTE 'CREATE POLICY "Users can view messages they sent or received"
      ON chat_messages FOR SELECT
      USING ((select auth.uid()) = sender_id OR (select auth.uid()) = receiver_id)';

    EXECUTE 'CREATE POLICY "Users can insert messages they send"
      ON chat_messages FOR INSERT
      WITH CHECK ((select auth.uid()) = sender_id)';

    EXECUTE 'CREATE POLICY "Users can update messages they received (mark as read)"
      ON chat_messages FOR UPDATE
      USING ((select auth.uid()) = receiver_id)';
  END IF;
END $$;

-- =====================================================
-- USER PRESENCE (IF EXISTS)
-- =====================================================

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_presence') THEN
    EXECUTE 'CREATE POLICY "Authenticated users can view presence"
      ON user_presence FOR SELECT
      USING ((select auth.uid()) IS NOT NULL)';

    EXECUTE 'CREATE POLICY "Users can manage their own presence"
      ON user_presence FOR ALL
      USING ((select auth.uid()) = user_id)';
  END IF;
END $$;

-- =====================================================
-- DROP DUPLICATE INDEXES
-- =====================================================

-- chat_messages duplicate indexes
DROP INDEX IF EXISTS idx_chat_messages_created_at;
DROP INDEX IF EXISTS idx_chat_messages_receiver;
DROP INDEX IF EXISTS idx_chat_messages_sender;

-- Note: unique_provider_service is a constraint, not a duplicate index
-- Keep the primary indexes:
-- - chat_messages_created_at_idx
-- - chat_messages_receiver_id_idx
-- - chat_messages_sender_id_idx
-- - provider_services_provider_id_service_category_id_key
