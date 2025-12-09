-- ============================================================
-- FIX: Calculate Progress for Solo Projects
-- ============================================================
-- Issue: Progress is 0% because tasks are not assigned to anyone
-- Solution: For solo projects, count ALL tasks in project
-- ============================================================

-- Drop and recreate the function with proper logic
DROP FUNCTION IF EXISTS calculate_user_progress(UUID, UUID);

CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID, p_project_id UUID)
RETURNS DECIMAL(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_tasks INTEGER;
  v_completed_tasks INTEGER;
  v_progress DECIMAL(5,2);
  v_user_role TEXT;
BEGIN
  -- Get user's role in the project
  SELECT role INTO v_user_role
  FROM user_projects
  WHERE user_id = p_user_id AND project_id = p_project_id;
  
  -- For SOLO projects, count ALL tasks in the project
  IF v_user_role = 'solo' THEN
    SELECT COUNT(*) INTO v_total_tasks
    FROM tasks
    WHERE project_id = p_project_id;
    
    SELECT COUNT(*) INTO v_completed_tasks
    FROM tasks
    WHERE project_id = p_project_id
      AND status = 'done';
  
  -- For multiplayer projects, only count assigned/claimed tasks
  ELSE
    SELECT COUNT(*) INTO v_total_tasks
    FROM tasks
    WHERE project_id = p_project_id
      AND (assigned_user_id = p_user_id OR claimed_by_user_id = p_user_id);
    
    SELECT COUNT(*) INTO v_completed_tasks
    FROM tasks
    WHERE project_id = p_project_id
      AND (assigned_user_id = p_user_id OR claimed_by_user_id = p_user_id)
      AND status = 'done';
  END IF;
  
  -- Calculate progress percentage
  IF v_total_tasks = 0 THEN
    v_progress := 0.0;
  ELSE
    v_progress := ROUND((v_completed_tasks::DECIMAL / v_total_tasks::DECIMAL) * 100, 2);
  END IF;
  
  RETURN v_progress;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID, UUID) TO authenticated, service_role;

-- Manually recalculate all existing progress
DO $$
DECLARE
  v_rec RECORD;
  v_progress DECIMAL(5,2);
BEGIN
  FOR v_rec IN 
    SELECT user_id, project_id FROM user_projects
  LOOP
    v_progress := calculate_user_progress(v_rec.user_id, v_rec.project_id);
    
    UPDATE user_projects
    SET progress = v_progress,
        status = CASE 
          WHEN v_progress >= 100 THEN 'completed'
          WHEN v_progress > 0 THEN 'in_progress'
          ELSE 'in_progress'
        END,
        completed_at = CASE 
          WHEN v_progress >= 100 THEN NOW()
          ELSE NULL
        END
    WHERE user_id = v_rec.user_id AND project_id = v_rec.project_id;
  END LOOP;
  
  RAISE NOTICE 'Progress recalculated for all users';
END $$;

-- Verify the updated progress
SELECT 
  p.title as project,
  pr.name as user_name,
  up.role,
  up.progress,
  up.status
FROM user_projects up
JOIN profiles pr ON up.user_id = pr.id
JOIN projects p ON up.project_id = p.id
ORDER BY p.title, pr.name;
