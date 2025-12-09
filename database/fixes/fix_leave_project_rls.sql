-- ============================================================
-- FIX: Allow Users to Leave Projects (DELETE user_projects)
-- ============================================================
-- Issue: User tidak bisa leave project
-- Root Cause: Kemungkinan tidak ada RLS policy DELETE atau policy terlalu restrictive
-- Solution: Allow users to delete their own user_projects entry
-- ============================================================

-- Drop existing DELETE policy if any
DROP POLICY IF EXISTS user_projects_delete_own ON user_projects;

-- Create policy: Users can delete their own membership
CREATE POLICY user_projects_delete_own ON user_projects
  FOR DELETE
  USING (
    -- User can delete their own membership
    user_id = auth.uid()
    OR
    -- Admin can delete any membership
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
