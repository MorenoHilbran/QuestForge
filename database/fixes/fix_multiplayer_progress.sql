-- ============================================================
-- FIX: Update Progress Calculation for Role-Based Tasks
-- ============================================================
-- Issue: Team member progress shows 0% in multiplayer projects
-- Solution: Update calculate_user_progress to consider assigned_role
-- ============================================================

-- Drop existing function
DROP FUNCTION IF EXISTS calculate_user_progress(UUID, UUID);

-- Create updated function that considers assigned_role
CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID, p_project_id UUID)
RETURNS DECIMAL(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_tasks INTEGER;
  v_completed_tasks INTEGER;
  v_progress DECIMAL(5,2);
  v_mode TEXT;
  v_user_role TEXT;
BEGIN
  -- Get project mode
  SELECT mode INTO v_mode
  FROM projects
  WHERE id = p_project_id;

  -- Get user's role in this project
  SELECT role INTO v_user_role
  FROM user_projects
  WHERE user_id = p_user_id AND project_id = p_project_id;

  IF v_mode = 'solo' THEN
    -- Solo mode: count ALL tasks in project
    SELECT COUNT(*) INTO v_total_tasks
    FROM tasks
    WHERE project_id = p_project_id;

    SELECT COUNT(*) INTO v_completed_tasks
    FROM tasks
    WHERE project_id = p_project_id
      AND status = 'done';
      
  ELSIF v_mode = 'multiplayer' THEN
    -- Multiplayer mode: 
    -- - PM counts all tasks (including general tasks)
    -- - Other roles count ONLY tasks assigned to their role (NOT general tasks)
    IF v_user_role = 'pm' OR v_user_role = 'project_manager' THEN
      -- PM: count all tasks
      SELECT COUNT(*) INTO v_total_tasks
      FROM tasks
      WHERE project_id = p_project_id;

      SELECT COUNT(*) INTO v_completed_tasks
      FROM tasks
      WHERE project_id = p_project_id
        AND status = 'done';
    ELSE
      -- Regular members: only tasks assigned to their role (NOT NULL)
      SELECT COUNT(*) INTO v_total_tasks
      FROM tasks
      WHERE project_id = p_project_id
        AND assigned_role = v_user_role;

      SELECT COUNT(*) INTO v_completed_tasks
      FROM tasks
      WHERE project_id = p_project_id
        AND status = 'done'
        AND assigned_role = v_user_role;
    END IF;
  ELSE
    -- Default fallback
    v_total_tasks := 0;
    v_completed_tasks := 0;
  END IF;

  -- Calculate progress percentage
  IF v_total_tasks = 0 THEN
    v_progress := 0;
  ELSE
    v_progress := (v_completed_tasks::DECIMAL / v_total_tasks::DECIMAL) * 100;
  END IF;

  RETURN v_progress;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID, UUID) TO authenticated, service_role;

-- Manually recalculate progress for all active multiplayer projects
DO $$
DECLARE
  v_record RECORD;
BEGIN
  FOR v_record IN 
    SELECT up.user_id, up.project_id
    FROM user_projects up
    JOIN projects p ON up.project_id = p.id
    WHERE p.mode = 'multiplayer'
      AND up.status = 'in_progress'
  LOOP
    UPDATE user_projects
    SET progress = calculate_user_progress(v_record.user_id, v_record.project_id)
    WHERE user_id = v_record.user_id 
      AND project_id = v_record.project_id;
      
    RAISE NOTICE 'Updated progress for user % in project %', v_record.user_id, v_record.project_id;
  END LOOP;
END $$;

-- Verify: Check updated progress
SELECT 
  pr.name as user_name,
  p.title as project_name,
  p.mode,
  up.role,
  up.progress,
  COUNT(t.id) FILTER (WHERE t.assigned_role IS NULL OR t.assigned_role = up.role) as total_tasks,
  COUNT(t.id) FILTER (WHERE (t.assigned_role IS NULL OR t.assigned_role = up.role) AND t.status = 'done') as completed_tasks
FROM user_projects up
JOIN profiles pr ON up.user_id = pr.id
JOIN projects p ON up.project_id = p.id
LEFT JOIN tasks t ON t.project_id = p.id
WHERE p.mode = 'multiplayer'
  AND up.status = 'in_progress'
GROUP BY pr.name, p.title, p.mode, up.role, up.progress
ORDER BY p.title, up.role;
