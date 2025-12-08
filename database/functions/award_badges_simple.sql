-- Simplified badge checking and awarding function
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION award_badges_on_completion(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_completed_count INTEGER;
  v_solo_count INTEGER;
  v_team_count INTEGER;
  v_easy_count INTEGER;
  v_medium_count INTEGER;
  v_hard_count INTEGER;
  v_badge_id UUID;
BEGIN
  -- Count total completed projects
  SELECT COUNT(*) INTO v_completed_count
  FROM user_projects up
  WHERE up.user_id = p_user_id
    AND up.status = 'completed';

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

  -- Award "First Quest Complete" (1 project)
  IF v_completed_count >= 1 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'First Quest Complete';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  -- Award "Quest Master" (5 projects)
  IF v_completed_count >= 5 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'Quest Master';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  -- Award "Legendary Quester" (10 projects)
  IF v_completed_count >= 10 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'Legendary Quester';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  -- Award "Solo Warrior" (3 solo projects)
  IF v_solo_count >= 3 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'Solo Warrior';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  -- Award "Team Player" (3 team projects)
  IF v_team_count >= 3 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'Team Player';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  -- Award difficulty badges
  IF v_easy_count >= 3 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'Easy Master';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  IF v_medium_count >= 3 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'Medium Master';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

  IF v_hard_count >= 3 THEN
    SELECT id INTO v_badge_id FROM badges WHERE name = 'Hard Hero';
    IF v_badge_id IS NOT NULL THEN
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge_id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END IF;

END;
$$;
