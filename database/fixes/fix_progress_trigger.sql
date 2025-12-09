-- ============================================================
-- FIX: Auto-Update User Progress on Task Status Change
-- ============================================================
-- Issue: Progress bar tidak bergerak di admin dan detail screen
-- Root Cause: Tidak ada trigger untuk update user_projects.progress
--             saat task status berubah
-- Solution: Buat trigger untuk auto-update progress
-- ============================================================

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS update_progress_on_task_change ON tasks;
DROP FUNCTION IF EXISTS update_user_progress_on_task_change() CASCADE;

-- Create function to update user progress when task changes
CREATE OR REPLACE FUNCTION update_user_progress_on_task_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_user RECORD;
BEGIN
  -- Update progress for all users in this project
  FOR v_user IN 
    SELECT user_id, project_id
    FROM user_projects
    WHERE project_id = NEW.project_id
      AND status = 'in_progress'
  LOOP
    UPDATE user_projects
    SET progress = calculate_user_progress(v_user.user_id, v_user.project_id)
    WHERE user_id = v_user.user_id 
      AND project_id = v_user.project_id;
  END LOOP;
  
  RETURN NEW;
END;
$$;

-- Create trigger on tasks table for INSERT and UPDATE
CREATE TRIGGER update_progress_on_task_change
  AFTER INSERT OR UPDATE OF status ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_user_progress_on_task_change();

-- Manually recalculate progress for ALL active projects (solo + multiplayer)
DO $$
DECLARE
  v_record RECORD;
BEGIN
  FOR v_record IN 
    SELECT up.user_id, up.project_id
    FROM user_projects up
    WHERE up.status = 'in_progress'
  LOOP
    UPDATE user_projects
    SET progress = calculate_user_progress(v_record.user_id, v_record.project_id)
    WHERE user_id = v_record.user_id 
      AND project_id = v_record.project_id;
  END LOOP;
  
  RAISE NOTICE 'Recalculated progress for all active projects';
END $$;
