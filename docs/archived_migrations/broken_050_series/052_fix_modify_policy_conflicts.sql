-- =====================================================
-- Migration: Fix modify_policy conflicts with select_policy
-- Splits FOR ALL policies into separate INSERT/UPDATE/DELETE
-- =====================================================

-- =====================================================
-- 1. FIX PORTFOLIO_IMAGES
-- =====================================================

DROP POLICY IF EXISTS "portfolio_images_modify_policy" ON portfolio_images;

CREATE POLICY "portfolio_images_insert_policy"
  ON portfolio_images FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = provider_id);

CREATE POLICY "portfolio_images_update_policy"
  ON portfolio_images FOR UPDATE
  USING ((SELECT auth.uid()) = provider_id);

CREATE POLICY "portfolio_images_delete_policy"
  ON portfolio_images FOR DELETE
  USING ((SELECT auth.uid()) = provider_id);

-- =====================================================
-- 2. FIX PROVIDER_SERVICES
-- =====================================================

DROP POLICY IF EXISTS "provider_services_modify_policy" ON provider_services;

CREATE POLICY "provider_services_insert_policy"
  ON provider_services FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = provider_id);

CREATE POLICY "provider_services_update_policy"
  ON provider_services FOR UPDATE
  USING ((SELECT auth.uid()) = provider_id);

CREATE POLICY "provider_services_delete_policy"
  ON provider_services FOR DELETE
  USING ((SELECT auth.uid()) = provider_id);

-- =====================================================
-- 3. FIX TESTIMONIALS
-- =====================================================

DROP POLICY IF EXISTS "testimonials_modify_policy" ON testimonials;

-- Testimonials modify policy for admins only
CREATE POLICY "testimonials_insert_policy"
  ON testimonials FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
  );

CREATE POLICY "testimonials_update_policy"
  ON testimonials FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
  );

CREATE POLICY "testimonials_delete_policy"
  ON testimonials FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
  );

-- =====================================================
-- 4. FIX USER_PRESENCE
-- =====================================================

DROP POLICY IF EXISTS "user_presence_modify_policy" ON user_presence;

CREATE POLICY "user_presence_insert_policy"
  ON user_presence FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "user_presence_update_policy"
  ON user_presence FOR UPDATE
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "user_presence_delete_policy"
  ON user_presence FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

-- =====================================================
-- 5. FIX SERVICES (if exists)
-- =====================================================

DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='services') THEN
    DROP POLICY IF EXISTS "services_modify_policy" ON services;

    -- Check which ID column exists and create appropriate policies
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='services' AND column_name='provider_id') THEN
      EXECUTE 'CREATE POLICY "services_insert_policy"
        ON services FOR INSERT
        WITH CHECK ((SELECT auth.uid()) = provider_id)';
      
      EXECUTE 'CREATE POLICY "services_update_policy"
        ON services FOR UPDATE
        USING ((SELECT auth.uid()) = provider_id)';
      
      EXECUTE 'CREATE POLICY "services_delete_policy"
        ON services FOR DELETE
        USING ((SELECT auth.uid()) = provider_id)';
        
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='services' AND column_name='labourer_id') THEN
      EXECUTE 'CREATE POLICY "services_insert_policy"
        ON services FOR INSERT
        WITH CHECK ((SELECT auth.uid()) = labourer_id)';
      
      EXECUTE 'CREATE POLICY "services_update_policy"
        ON services FOR UPDATE
        USING ((SELECT auth.uid()) = labourer_id)';
      
      EXECUTE 'CREATE POLICY "services_delete_policy"
        ON services FOR DELETE
        USING ((SELECT auth.uid()) = labourer_id)';
        
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='services' AND column_name='user_id') THEN
      EXECUTE 'CREATE POLICY "services_insert_policy"
        ON services FOR INSERT
        WITH CHECK ((SELECT auth.uid()) = user_id)';
      
      EXECUTE 'CREATE POLICY "services_update_policy"
        ON services FOR UPDATE
        USING ((SELECT auth.uid()) = user_id)';
      
      EXECUTE 'CREATE POLICY "services_delete_policy"
        ON services FOR DELETE
        USING ((SELECT auth.uid()) = user_id)';
    END IF;
  END IF;
END $$;

-- =====================================================
-- 6. FIX PROVIDER_CATEGORIES (if exists)
-- =====================================================

DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='provider_categories') THEN
    DROP POLICY IF EXISTS "provider_categories_modify_policy" ON provider_categories;

    -- Check which ID column exists and create appropriate policies
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='provider_categories' AND column_name='provider_id') THEN
      EXECUTE 'CREATE POLICY "provider_categories_insert_policy"
        ON provider_categories FOR INSERT
        WITH CHECK ((SELECT auth.uid()) = provider_id)';
      
      EXECUTE 'CREATE POLICY "provider_categories_update_policy"
        ON provider_categories FOR UPDATE
        USING ((SELECT auth.uid()) = provider_id)';
      
      EXECUTE 'CREATE POLICY "provider_categories_delete_policy"
        ON provider_categories FOR DELETE
        USING ((SELECT auth.uid()) = provider_id)';
        
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='provider_categories' AND column_name='user_id') THEN
      EXECUTE 'CREATE POLICY "provider_categories_insert_policy"
        ON provider_categories FOR INSERT
        WITH CHECK ((SELECT auth.uid()) = user_id)';
      
      EXECUTE 'CREATE POLICY "provider_categories_update_policy"
        ON provider_categories FOR UPDATE
        USING ((SELECT auth.uid()) = user_id)';
      
      EXECUTE 'CREATE POLICY "provider_categories_delete_policy"
        ON provider_categories FOR DELETE
        USING ((SELECT auth.uid()) = user_id)';
    END IF;
  END IF;
END $$;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- This migration has:
-- ✅ Split FOR ALL policies into separate INSERT/UPDATE/DELETE policies
-- ✅ Eliminated conflicts between modify_policy and select_policy
-- ✅ Maintained all security restrictions with wrapped auth.uid()
-- 
-- Expected result: 0 warnings
