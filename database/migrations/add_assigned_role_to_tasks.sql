-- ============================================================
-- FEATURE: Role-Based Task Assignment for Multiplayer Projects
-- ============================================================
-- Add assigned_role column to tasks table
-- PM can assign tasks to specific roles
-- Users can only claim/complete tasks assigned to their role
-- ============================================================

-- Add assigned_role column to tasks table
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_role TEXT;

-- Add comment
COMMENT ON COLUMN tasks.assigned_role IS 'Role yang ditugaskan untuk task ini (designer, frontend, backend, etc). NULL berarti semua role bisa mengerjakan.';

-- Update existing tasks (solo projects don't need assigned_role)
-- For multiplayer projects without assigned_role, set to NULL (any role can claim)

-- Create index for faster filtering by role
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_role ON tasks(assigned_role);

-- Update RLS policies to allow users to see all tasks but only claim tasks for their role
-- Drop existing claim policy
DROP POLICY IF EXISTS tasks_claim_member ON tasks;

-- New policy: Users can only claim tasks if:
-- 1. Task is in their project (member of project)
-- 2. Task is not yet claimed OR claimed by them
-- 3. Task's assigned_role matches user's role OR assigned_role is NULL
CREATE POLICY tasks_claim_role_based ON tasks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND up.status = 'active'
    )
    AND (assigned_user_id IS NULL OR assigned_user_id = auth.uid())
    AND (
      assigned_role IS NULL 
      OR assigned_role = (
        SELECT role FROM user_projects 
        WHERE project_id = tasks.project_id 
          AND user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND up.status = 'active'
    )
    AND (
      assigned_role IS NULL 
      OR assigned_role = (
        SELECT role FROM user_projects 
        WHERE project_id = tasks.project_id 
          AND user_id = auth.uid()
      )
    )
  );

-- Policy for PM/Admin to assign tasks to roles
-- PM can update assigned_role for any task in their project
CREATE POLICY tasks_assign_role_pm ON tasks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND up.role = 'project_manager'
        AND up.status = 'active'
    )
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Grant permissions
GRANT SELECT ON tasks TO authenticated;
GRANT UPDATE ON tasks TO authenticated;

-- Verification query
SELECT 
  p.title as project_name,
  p.mode,
  t.title as task_title,
  t.assigned_role,
  t.assigned_user_id,
  t.status
FROM tasks t
JOIN projects p ON t.project_id = p.id
ORDER BY p.title, t.assigned_role, t.title;
