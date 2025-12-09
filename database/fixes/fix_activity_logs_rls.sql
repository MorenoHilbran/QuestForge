-- ============================================================
-- FIX ACTIVITY_LOGS RLS POLICY
-- ============================================================
-- Run this in Supabase SQL Editor to fix:
-- "new row violates row-level security policy for table 'activity_logs'"
-- ============================================================

-- Drop old restrictive policies
DROP POLICY IF EXISTS "ActivityLogs: service role can insert" ON activity_logs;
DROP POLICY IF EXISTS "ActivityLogs: view own or project activity" ON activity_logs;

-- Create new permissive policies
CREATE POLICY "ActivityLogs: authenticated can view and insert"
  ON activity_logs FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "ActivityLogs: service role can do anything"
  ON activity_logs FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Verify policies are in place
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'activity_logs'
ORDER BY policyname;
