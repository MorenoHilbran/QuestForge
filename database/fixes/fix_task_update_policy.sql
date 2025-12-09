-- ============================================================
-- FIX: Update Task RLS Policies for Role-Based Assignment
-- ============================================================
-- Issue: Backend developer tidak bisa checklist task yang di-assign
-- Solution: Perbaiki RLS policies untuk UPDATE tasks
-- ============================================================

-- Drop ALL existing UPDATE policies on tasks
DROP POLICY IF EXISTS tasks_update_all ON tasks;
DROP POLICY IF EXISTS tasks_update_pm_admin ON tasks;
DROP POLICY IF EXISTS tasks_claim_member ON tasks;
DROP POLICY IF EXISTS tasks_claim_role_based ON tasks;
DROP POLICY IF EXISTS tasks_assign_role_pm ON tasks;
DROP POLICY IF EXISTS tasks_update_members ON tasks;

-- Policy 1: Allow users to UPDATE tasks if:
-- - They are member of the project (in_progress)
-- - Task assigned_role matches their role (NOT NULL tasks)
-- - OR they are admin
-- - OR they are PM of the project
-- Note: General tasks (assigned_role = NULL) can only be updated by PM
CREATE POLICY tasks_update_members ON tasks
  FOR UPDATE
  USING (
    -- Admin can update all tasks
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
    OR
    -- PM can update all tasks in their project (including general tasks)
    -- Check both 'pm' and 'project_manager' role names
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND (up.role = 'pm' OR up.role = 'project_manager')
        AND up.status = 'in_progress'
    )
    OR
    -- Regular members can update ONLY if role matches (NOT general tasks)
    (
      EXISTS (
        SELECT 1 FROM user_projects up
        WHERE up.project_id = tasks.project_id
          AND up.user_id = auth.uid()
          AND up.status = 'in_progress'
          AND tasks.assigned_role IS NOT NULL  -- NOT general tasks
          AND tasks.assigned_role = up.role    -- Role must match
      )
    )
  )
  WITH CHECK (
    -- Same conditions for WITH CHECK
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
    OR
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND (up.role = 'pm' OR up.role = 'project_manager')
        AND up.status = 'in_progress'
    )
    OR
    (
      EXISTS (
        SELECT 1 FROM user_projects up
        WHERE up.project_id = tasks.project_id
          AND up.user_id = auth.uid()
          AND up.status = 'in_progress'
          AND tasks.assigned_role IS NOT NULL
          AND tasks.assigned_role = up.role
      )
    )
  );

-- Verify: Show policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'tasks' AND cmd = 'UPDATE';

-- Test query: Check if current user can see/update tasks
-- Run this after logging in as backend developer
SELECT 
  t.title,
  t.assigned_role,
  t.status,
  up.role as my_role,
  CASE 
    WHEN t.assigned_role IS NULL THEN 'Any role can update'
    WHEN t.assigned_role = up.role THEN 'Your role matches'
    WHEN up.role = 'fullstack' THEN 'Fullstack can do all'
    WHEN up.role = 'project_manager' THEN 'PM can do all'
    ELSE 'Cannot update (wrong role)'
  END as can_update
FROM tasks t
JOIN user_projects up ON t.project_id = up.project_id
WHERE up.user_id = auth.uid()
  AND up.status = 'in_progress'
ORDER BY t.project_id, t.assigned_role;
