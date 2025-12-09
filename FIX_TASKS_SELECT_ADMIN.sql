-- ============================================================
-- FIX: Tasks SELECT Policy for Admin
-- ============================================================
-- Issue: Admin can create tasks but cannot see them
-- Solution: Allow admin to see all tasks
-- ============================================================

-- Drop existing select policy
DROP POLICY IF EXISTS "tasks_select_joined" ON tasks;

-- Create new policy that allows:
-- 1. Admin can see all tasks
-- 2. Users can see tasks in projects they joined
CREATE POLICY "tasks_select_admin_joined" ON tasks 
  FOR SELECT 
  TO authenticated 
  USING (
    -- Admin can see all tasks
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    OR
    -- Users can see tasks in projects they joined
    EXISTS (
      SELECT 1 FROM user_projects 
      WHERE project_id = tasks.project_id 
        AND user_id = auth.uid()
    )
  );

-- Verify the policy
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'tasks' AND cmd = 'SELECT';
