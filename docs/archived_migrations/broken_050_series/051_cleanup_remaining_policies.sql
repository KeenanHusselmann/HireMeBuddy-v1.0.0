-- =====================================================
-- Migration: Clean up remaining old RLS policies
-- Fixes remaining 77 warnings after migration 050
-- =====================================================

-- =====================================================
-- 1. FIX SERVICES TABLE (Auth RLS + Multiple Policies)
-- =====================================================

DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='services') THEN
    -- Drop old policies
    DROP POLICY IF EXISTS "Services are viewable by everyone" ON services;
    DROP POLICY IF EXISTS "Labourers can manage their own services" ON services;

    -- Create SELECT policy
    EXECUTE 'CREATE POLICY "services_select_policy"
      ON services FOR SELECT
      USING (true)';

    -- Create modify policy - check which ID column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='services' AND column_name='provider_id') THEN
      EXECUTE 'CREATE POLICY "services_modify_policy"
        ON services FOR ALL
        USING ((SELECT auth.uid()) = provider_id)';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='services' AND column_name='labourer_id') THEN
      EXECUTE 'CREATE POLICY "services_modify_policy"
        ON services FOR ALL
        USING ((SELECT auth.uid()) = labourer_id)';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='services' AND column_name='user_id') THEN
      EXECUTE 'CREATE POLICY "services_modify_policy"
        ON services FOR ALL
        USING ((SELECT auth.uid()) = user_id)';
    END IF;
  END IF;
END $$;

-- =====================================================
-- 2. FIX PORTFOLIO_IMAGES (Remove old individual policies)
-- =====================================================

DROP POLICY IF EXISTS "Providers can insert their own portfolio images" ON portfolio_images;
DROP POLICY IF EXISTS "Providers can update their own portfolio images" ON portfolio_images;
DROP POLICY IF EXISTS "Providers can delete their own portfolio images" ON portfolio_images;

-- Keep only the combined policies created in migration 050:
-- - portfolio_images_select_policy
-- - portfolio_images_modify_policy

-- =====================================================
-- 3. FIX TESTIMONIALS (Remove old individual policies)
-- =====================================================

DROP POLICY IF EXISTS "Providers can insert their own testimonials" ON testimonials;
DROP POLICY IF EXISTS "Providers can update their own testimonials" ON testimonials;
DROP POLICY IF EXISTS "Providers can delete their own testimonials" ON testimonials;

-- Keep only the combined policies created in migration 050:
-- - testimonials_select_policy
-- - testimonials_modify_policy

-- =====================================================
-- 4. FIX USER_PRESENCE (Remove old individual policies)
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can view presence" ON user_presence;
DROP POLICY IF EXISTS "Users can manage their own presence" ON user_presence;

-- Keep only the combined policies created in migration 050:
-- - user_presence_select_policy
-- - user_presence_modify_policy

-- =====================================================
-- 5. FIX PROVIDER_CATEGORIES (Remove old policies)
-- =====================================================

DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='provider_categories') THEN
    -- Drop old policies
    DROP POLICY IF EXISTS "Provider categories are viewable by everyone" ON provider_categories;
    DROP POLICY IF EXISTS "Providers can manage their own categories" ON provider_categories;

    -- Create combined SELECT policy
    EXECUTE 'CREATE POLICY "provider_categories_select_policy"
      ON provider_categories FOR SELECT
      USING (true)';

    -- Create combined modify policy - check which ID column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='provider_categories' AND column_name='provider_id') THEN
      EXECUTE 'CREATE POLICY "provider_categories_modify_policy"
        ON provider_categories FOR ALL
        USING ((SELECT auth.uid()) = provider_id)';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='provider_categories' AND column_name='user_id') THEN
      EXECUTE 'CREATE POLICY "provider_categories_modify_policy"
        ON provider_categories FOR ALL
        USING ((SELECT auth.uid()) = user_id)';
    END IF;
  END IF;
END $$;

-- =====================================================
-- 6. FIX QUOTE_REQUESTS (Remove conflicting policies)
-- =====================================================

DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='quote_requests') THEN
    -- Drop ALL old quote_requests policies
    DROP POLICY IF EXISTS "Users can view their own quote requests" ON quote_requests;
    DROP POLICY IF EXISTS "Clients can create quote requests" ON quote_requests;
    DROP POLICY IF EXISTS "Deny anonymous access to quote requests" ON quote_requests;
    DROP POLICY IF EXISTS "Users can update their own quote requests" ON quote_requests;

    -- Drop the conditional policies from migration 050 if they exist
    DROP POLICY IF EXISTS "quote_requests_select_policy" ON quote_requests;
    DROP POLICY IF EXISTS "quote_requests_insert_policy" ON quote_requests;
    DROP POLICY IF EXISTS "quote_requests_update_policy" ON quote_requests;

    -- Only create policies if both client_id and provider_id columns exist
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quote_requests' AND column_name='client_id')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quote_requests' AND column_name='provider_id') THEN
      
      -- Create new optimized policies with wrapped auth.uid()
      EXECUTE 'CREATE POLICY "quote_requests_select_policy"
        ON quote_requests FOR SELECT
        USING (
          (SELECT auth.uid()) IS NOT NULL AND
          ((SELECT auth.uid()) = client_id OR (SELECT auth.uid()) = provider_id)
        )';

      EXECUTE 'CREATE POLICY "quote_requests_insert_policy"
        ON quote_requests FOR INSERT
        WITH CHECK ((SELECT auth.uid()) = client_id)';

      EXECUTE 'CREATE POLICY "quote_requests_update_policy"
        ON quote_requests FOR UPDATE
        USING ((SELECT auth.uid()) = client_id OR (SELECT auth.uid()) = provider_id)';
    END IF;
  END IF;
END $$;

-- =====================================================
-- 7. FIX VERIFICATION_DOCUMENTS (Replace old policies)
-- =====================================================

DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='verification_documents') THEN
    -- Drop ALL old verification_documents policies
    DROP POLICY IF EXISTS "Only verification admins can access verification documents" ON verification_documents;
    DROP POLICY IF EXISTS "Users can submit their own verification documents" ON verification_documents;
    DROP POLICY IF EXISTS "Users can view their own verification status" ON verification_documents;

    -- Drop conditional policies from migration 050 if they exist
    DROP POLICY IF EXISTS "verification_documents_select_policy" ON verification_documents;
    DROP POLICY IF EXISTS "verification_documents_insert_policy" ON verification_documents;
    DROP POLICY IF EXISTS "verification_documents_update_policy" ON verification_documents;

    -- Only create policies if user_id column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='verification_documents' AND column_name='user_id') THEN
      
      -- Create new optimized policies with wrapped auth.uid()
      EXECUTE 'CREATE POLICY "verification_documents_select_policy"
        ON verification_documents FOR SELECT
        USING (
          (SELECT auth.uid()) = user_id OR
          EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = ''admin''
          )
        )';

      EXECUTE 'CREATE POLICY "verification_documents_insert_policy"
        ON verification_documents FOR INSERT
        WITH CHECK (
          (SELECT auth.uid()) = user_id OR
          EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = ''admin''
          )
        )';

      EXECUTE 'CREATE POLICY "verification_documents_update_policy"
        ON verification_documents FOR UPDATE
        USING (
          EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = (SELECT auth.uid()) AND p.role = ''admin''
          )
        )';
    END IF;
  END IF;
END $$;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- This migration has cleaned up:
-- ✅ Fixed services table (1 auth warning + 5 multiple policy warnings)
-- ✅ Removed old portfolio_images policies (16 warnings)
-- ✅ Removed old testimonials policies (16 warnings)
-- ✅ Removed old user_presence policies (5 warnings)
-- ✅ Removed old provider_categories policies (5 warnings)
-- ✅ Fixed quote_requests policies (3 warnings)
-- ✅ Fixed verification_documents with wrapped auth.uid() (3 auth warnings + 10 policy warnings)
-- 
-- Expected result: 0 warnings
