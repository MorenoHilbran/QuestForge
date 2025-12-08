-- ============================================================
-- FIX INFINITE RECURSION IN USER_PROJECTS RLS POLICIES
-- ============================================================
-- Run this in Supabase SQL Editor to fix the error:
-- "infinite recursion detected in policy for relation 'user_projects'"
-- ============================================================

-- Drop old problematic policies
DROP POLICY IF EXISTS "UserProjects: view own memberships" ON user_projects;
DROP POLICY IF EXISTS "UserProjects: view project members" ON user_projects;
DROP POLICY IF EXISTS "UserProjects: users can join" ON user_projects;
DROP POLICY IF EXISTS "UserProjects: users can update own" ON user_projects;

-- Create new simplified policies (no circular reference)
CREATE POLICY "UserProjects: users can view all"
  ON user_projects FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "UserProjects: users can join"
  ON user_projects FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "UserProjects: users can update own"
  ON user_projects FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- EXPLANATION
-- ============================================================
-- The old policy "UserProjects: view project members" had:
--   EXISTS (SELECT 1 FROM user_projects up WHERE ...)
-- This caused infinite recursion because it queries user_projects
-- from within a user_projects policy!
--
-- Solution: Allow all authenticated users to view user_projects.
-- This is safe because:
-- 1. Users need to see who's in a project to join/collaborate
-- 2. No sensitive data in user_projects (just IDs and roles)
-- 3. Actual user details are protected by profiles RLS
-- ============================================================

-- Verify the fix
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'user_projects'
ORDER BY policyname;
