-- ============================================================
-- FIX: Solo Mode Task Update Permission
-- ============================================================
-- Issue: User di solo mode tidak bisa check task
-- Root Cause: RLS policy tasks_update_members memblokir task
--             dengan assigned_role = NULL untuk non-PM
-- Solution: Allow solo mode users to update tasks in their solo project
-- ============================================================

-- Drop existing policy
DROP POLICY IF EXISTS tasks_update_members ON tasks;

-- Recreate with solo mode support
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
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND (up.role = 'pm' OR up.role = 'project_manager')
        AND up.status = 'in_progress'
    )
    OR
    -- SOLO MODE: User can update ANY task in solo project they joined
    EXISTS (
      SELECT 1 
      FROM user_projects up
      JOIN projects p ON p.id = up.project_id
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND up.status = 'in_progress'
        AND p.mode = 'solo'
    )
    OR
    -- MULTIPLAYER: Members can update if role matches (NOT general tasks)
    EXISTS (
      SELECT 1 
      FROM user_projects up
      JOIN projects p ON p.id = up.project_id
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND up.status = 'in_progress'
        AND p.mode = 'multiplayer'
        AND tasks.assigned_role IS NOT NULL  -- NOT general tasks
        AND tasks.assigned_role = up.role    -- Role must match
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
    EXISTS (
      SELECT 1 
      FROM user_projects up
      JOIN projects p ON p.id = up.project_id
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND up.status = 'in_progress'
        AND p.mode = 'solo'
    )
    OR
    EXISTS (
      SELECT 1 
      FROM user_projects up
      JOIN projects p ON p.id = up.project_id
      WHERE up.project_id = tasks.project_id
        AND up.user_id = auth.uid()
        AND up.status = 'in_progress'
        AND p.mode = 'multiplayer'
        AND tasks.assigned_role IS NOT NULL
        AND tasks.assigned_role = up.role
    )
  );
