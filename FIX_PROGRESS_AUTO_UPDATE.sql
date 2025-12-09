-- ============================================================
-- FIX: Auto-Update Progress When Tasks Change
-- ============================================================
-- Issue: Progress stays at 0% even after completing tasks
-- Solution: Add trigger to auto-calculate progress
-- ============================================================

-- Function to calculate user progress in a project
CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID, p_project_id UUID)
RETURNS DECIMAL(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_tasks INTEGER;
  v_completed_tasks INTEGER;
  v_progress DECIMAL(5,2);
BEGIN
  -- Count total tasks assigned to or claimed by user
  SELECT COUNT(*) INTO v_total_tasks
  FROM tasks
  WHERE project_id = p_project_id
    AND (assigned_user_id = p_user_id OR claimed_by_user_id = p_user_id);
  
  -- Count completed tasks
  SELECT COUNT(*) INTO v_completed_tasks
  FROM tasks
  WHERE project_id = p_project_id
    AND (assigned_user_id = p_user_id OR claimed_by_user_id = p_user_id)
    AND status = 'done';
  
  -- Calculate progress percentage
  IF v_total_tasks = 0 THEN
    v_progress := 0.0;
  ELSE
    v_progress := ROUND((v_completed_tasks::DECIMAL / v_total_tasks::DECIMAL) * 100, 2);
  END IF;
  
  RETURN v_progress;
END;
$$;

-- Function to auto-update progress when tasks change
CREATE OR REPLACE FUNCTION auto_update_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_id UUID;
  v_project_id UUID;
  v_new_progress DECIMAL(5,2);
BEGIN
  -- Get project_id from NEW or OLD
  v_project_id := COALESCE(NEW.project_id, OLD.project_id);
  
  -- Update progress for all users in this project
  FOR v_user_id IN 
    SELECT DISTINCT user_id 
    FROM user_projects 
    WHERE project_id = v_project_id
  LOOP
    v_new_progress := calculate_user_progress(v_user_id, v_project_id);
    
    UPDATE user_projects
    SET progress = v_new_progress,
        status = CASE 
          WHEN v_new_progress >= 100 THEN 'completed'
          WHEN v_new_progress > 0 THEN 'in_progress'
          ELSE 'in_progress'
        END,
        completed_at = CASE 
          WHEN v_new_progress >= 100 THEN NOW()
          ELSE completed_at
        END
    WHERE user_id = v_user_id AND project_id = v_project_id;
  END LOOP;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Drop existing triggers if any
DROP TRIGGER IF EXISTS trigger_auto_update_progress_insert ON tasks;
DROP TRIGGER IF EXISTS trigger_auto_update_progress_update ON tasks;
DROP TRIGGER IF EXISTS trigger_auto_update_progress_delete ON tasks;

-- Create triggers on tasks table
CREATE TRIGGER trigger_auto_update_progress_insert
  AFTER INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_progress();

CREATE TRIGGER trigger_auto_update_progress_update
  AFTER UPDATE ON tasks
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status 
        OR OLD.assigned_user_id IS DISTINCT FROM NEW.assigned_user_id
        OR OLD.claimed_by_user_id IS DISTINCT FROM NEW.claimed_by_user_id)
  EXECUTE FUNCTION auto_update_progress();

CREATE TRIGGER trigger_auto_update_progress_delete
  AFTER DELETE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_progress();

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION auto_update_progress() TO authenticated, service_role;

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
          ELSE completed_at
        END
    WHERE user_id = v_rec.user_id AND project_id = v_rec.project_id;
  END LOOP;
  
  RAISE NOTICE 'Progress recalculated for all users';
END $$;

-- Verify
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
