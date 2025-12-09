-- ============================================================
-- FIX SERVICE_ROLE PERMISSIONS FOR TRIGGERS
-- ============================================================
-- Run this in Supabase SQL Editor if you encounter RLS errors
-- from triggers trying to INSERT/UPDATE other tables
-- ============================================================

-- Fix user_projects table - allow service_role for auto-tracking
DO $$ 
BEGIN
  -- Drop old policy if exists
  DROP POLICY IF EXISTS "UserProjects: service role can do anything" ON user_projects;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE POLICY "UserProjects: service role can do anything"
  ON user_projects FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Fix badges table - allow service_role for auto-awarding
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Badges: service role can do anything" ON badges;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE POLICY "Badges: service role can do anything"
  ON badges FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Fix user_badges table - allow service_role for auto-awarding
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "UserBadges: service role can do anything" ON user_badges;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE POLICY "UserBadges: service role can do anything"
  ON user_badges FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Verify all service_role policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE (qual ILIKE '%service_role%'
  OR with_check ILIKE '%service_role%'
  OR policyname ILIKE '%service role%')
ORDER BY tablename, policyname;
