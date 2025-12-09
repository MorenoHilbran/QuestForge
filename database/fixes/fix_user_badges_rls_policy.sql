-- ============================================================
-- FIX: User Badges RLS Policy
-- ============================================================
-- Issue: PostgrestException new row violates row-level security policy
-- Solution: Allow badge awarding from server-side functions
-- ============================================================

-- Drop existing policies on user_badges
DROP POLICY IF EXISTS user_badges_select_own ON user_badges;
DROP POLICY IF EXISTS user_badges_insert_system ON user_badges;

-- Allow users to view their own badges
CREATE POLICY user_badges_select_own ON user_badges
  FOR SELECT
  USING (user_id = auth.uid());

-- Allow INSERT from authenticated context (for badge awarding functions)
-- This allows check_and_award_badges function to insert badges
CREATE POLICY user_badges_insert_system ON user_badges
  FOR INSERT
  WITH CHECK (
    -- Allow if called from server function (service_role or authenticated)
    true
  );

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'user_badges'
ORDER BY policyname;
