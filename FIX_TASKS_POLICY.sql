-- ============================================================
-- FIX: Tasks RLS Policy for Admin and PM
-- ============================================================
-- Error: new row violates row-level security policy for table "tasks"
-- Solution: Add policy for admin to create tasks
-- ============================================================

-- Drop existing task insert policy
DROP POLICY IF EXISTS "tasks_insert_pm" ON tasks;

-- Create new policy that allows:
-- 1. PM/Solo users in the project to create tasks
-- 2. Admin users to create tasks for any project
CREATE POLICY "tasks_insert_pm_admin" ON tasks 
  FOR INSERT 
  TO authenticated 
  WITH CHECK (
    -- Admin can create tasks for any project
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    OR
    -- PM/Solo can create tasks for their projects
    EXISTS (
      SELECT 1 FROM user_projects 
      WHERE project_id = tasks.project_id 
        AND user_id = auth.uid() 
        AND role IN ('pm', 'solo')
    )
  );

-- Also check update policy
DROP POLICY IF EXISTS "tasks_update_assigned" ON tasks;

-- Allow task updates by:
-- 1. Admin
-- 2. Assigned user
-- 3. Claimed user
-- 4. PM of the project
CREATE POLICY "tasks_update_all" ON tasks 
  FOR UPDATE 
  TO authenticated 
  USING (
    -- Admin can update any task
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    OR
    -- Assigned or claimed user can update
    assigned_user_id = auth.uid() 
    OR 
    claimed_by_user_id = auth.uid()
    OR
    -- PM can update tasks in their project
    EXISTS (
      SELECT 1 FROM user_projects 
      WHERE project_id = tasks.project_id 
        AND user_id = auth.uid() 
        AND role IN ('pm', 'solo')
    )
  );

-- Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'tasks'
ORDER BY policyname;
