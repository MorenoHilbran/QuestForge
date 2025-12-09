-- ============================================================
-- Add Project Completion Feature
-- ============================================================
-- Feature: PM can mark project as completed to award badges
-- ============================================================

-- Add completed_at column to projects
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Add status column to projects (planning, in_progress, completed)
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'in_progress'
CHECK (status IN ('planning', 'in_progress', 'completed'));

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_completed_at ON projects(completed_at);

-- Function to complete project and award badges
CREATE OR REPLACE FUNCTION complete_project(p_project_id UUID, p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_pm BOOLEAN;
  v_all_tasks_done BOOLEAN;
  v_project_mode TEXT;
  v_result JSON;
BEGIN
  -- Check if user is PM of this project
  SELECT EXISTS (
    SELECT 1 FROM user_projects
    WHERE project_id = p_project_id
      AND user_id = p_user_id
      AND (role = 'pm' OR role = 'project_manager')
      AND status = 'in_progress'
  ) INTO v_is_pm;

  IF NOT v_is_pm THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Only Project Manager can complete the project'
    );
  END IF;

  -- Check if all tasks are completed
  SELECT NOT EXISTS (
    SELECT 1 FROM tasks
    WHERE project_id = p_project_id
      AND status != 'done'
  ) INTO v_all_tasks_done;

  IF NOT v_all_tasks_done THEN
    RETURN json_build_object(
      'success', false,
      'message', 'All tasks must be completed before marking project as done'
    );
  END IF;

  -- Get project mode
  SELECT mode INTO v_project_mode FROM projects WHERE id = p_project_id;

  -- Mark project as completed
  UPDATE projects
  SET status = 'completed',
      completed_at = NOW()
  WHERE id = p_project_id;

  -- Mark all user_projects as completed
  UPDATE user_projects
  SET status = 'completed',
      progress = 100
  WHERE project_id = p_project_id;

  -- Award badges to all team members
  PERFORM check_and_award_badges(up.user_id)
  FROM user_projects up
  WHERE up.project_id = p_project_id;

  RETURN json_build_object(
    'success', true,
    'message', 'Project completed successfully! Badges awarded to team members.'
  );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION complete_project(UUID, UUID) TO authenticated, service_role;

-- Update existing projects to have status
UPDATE projects 
SET status = 'in_progress' 
WHERE status IS NULL;

COMMENT ON COLUMN projects.status IS 'Project status: planning, in_progress, completed';
COMMENT ON COLUMN projects.completed_at IS 'Timestamp when project was marked as completed';
COMMENT ON FUNCTION complete_project IS 'Complete project and award badges to team members (PM only)';
