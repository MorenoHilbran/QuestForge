-- ============================================================
-- QUICK FIX: USER_PROJECTS SERVICE ROLE PERMISSION
-- ============================================================
-- Run this FIRST before testing join project feature
-- ============================================================

-- Add service_role permission to user_projects
CREATE POLICY "UserProjects: service role can do anything"
  ON user_projects FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Verify policy created
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'user_projects'
ORDER BY policyname;
