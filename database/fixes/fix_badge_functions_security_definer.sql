-- ============================================================
-- FIX: Add SECURITY DEFINER to Badge Functions
-- ============================================================
-- Issue: Functions need to bypass RLS to insert badges
-- Solution: Add SECURITY DEFINER to run with elevated privileges
-- ============================================================

-- Recreate check_and_award_badges with SECURITY DEFINER
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- This allows function to bypass RLS
SET search_path = public
AS $$
DECLARE
  v_completed_count INTEGER;
  v_easy_count INTEGER;
  v_medium_count INTEGER;
  v_hard_count INTEGER;
  v_solo_count INTEGER;
  v_team_count INTEGER;
BEGIN
  -- Count completed projects by user
  SELECT COUNT(*) INTO v_completed_count
  FROM user_projects up
  WHERE up.user_id = p_user_id
    AND up.status = 'completed';

  -- Count by difficulty
  SELECT COUNT(*) INTO v_easy_count
  FROM user_projects up
  JOIN projects p ON up.project_id = p.id
  WHERE up.user_id = p_user_id
    AND up.status = 'completed'
    AND p.difficulty = 'easy';

  SELECT COUNT(*) INTO v_medium_count
  FROM user_projects up
  JOIN projects p ON up.project_id = p.id
  WHERE up.user_id = p_user_id
    AND up.status = 'completed'
    AND p.difficulty = 'medium';

  SELECT COUNT(*) INTO v_hard_count
  FROM user_projects up
  JOIN projects p ON up.project_id = p.id
  WHERE up.user_id = p_user_id
    AND up.status = 'completed'
    AND p.difficulty = 'hard';

  -- Count by mode
  SELECT COUNT(*) INTO v_solo_count
  FROM user_projects up
  JOIN projects p ON up.project_id = p.id
  WHERE up.user_id = p_user_id
    AND up.status = 'completed'
    AND p.mode = 'solo';

  SELECT COUNT(*) INTO v_team_count
  FROM user_projects up
  JOIN projects p ON up.project_id = p.id
  WHERE up.user_id = p_user_id
    AND up.status = 'completed'
    AND p.mode = 'multiplayer';

  -- Award "First Quest" badge (complete 1 project)
  IF v_completed_count >= 1 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'First Quest'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

  -- Award "Quest Master" badge (complete 5 projects)
  IF v_completed_count >= 5 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'Quest Master'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

  -- Award "Legendary Quester" badge (complete 10 projects)
  IF v_completed_count >= 10 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'Legendary Quester'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

  -- Award "Easy Conqueror" badge (complete 3 easy projects)
  IF v_easy_count >= 3 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'Easy Conqueror'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

  -- Award "Medium Master" badge (complete 3 medium projects)
  IF v_medium_count >= 3 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'Medium Master'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

  -- Award "Hard Hero" badge (complete 3 hard projects)
  IF v_hard_count >= 3 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'Hard Hero'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

  -- Award "Solo Warrior" badge (complete 3 solo projects)
  IF v_solo_count >= 3 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'Solo Warrior'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

  -- Award "Team Player" badge (complete 3 team projects)
  IF v_team_count >= 3 THEN
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, id FROM badges WHERE name = 'Team Player'
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;

END;
$$;

-- Also update complete_project function to use SECURITY DEFINER
CREATE OR REPLACE FUNCTION complete_project(p_project_id UUID, p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER  -- This allows function to bypass RLS
SET search_path = public
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
GRANT EXECUTE ON FUNCTION check_and_award_badges(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION complete_project(UUID, UUID) TO authenticated, service_role;

-- Verify functions have SECURITY DEFINER
SELECT 
  p.proname as function_name,
  CASE p.prosecdef 
    WHEN true THEN 'SECURITY DEFINER'
    ELSE 'SECURITY INVOKER'
  END as security_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('check_and_award_badges', 'complete_project');
