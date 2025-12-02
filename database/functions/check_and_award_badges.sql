-- Function to check and award badges when user completes a project
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION check_and_award_badges(UUID) TO authenticated;
