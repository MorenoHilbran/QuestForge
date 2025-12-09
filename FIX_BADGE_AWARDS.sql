-- ============================================================
-- FIX: Auto-Award Badges System
-- ============================================================
-- Issue: Badges not awarded even after completing projects
-- Solution: Create trigger to auto-award badges when project completed
-- ============================================================

-- Create trigger function to auto-award badges
CREATE OR REPLACE FUNCTION auto_award_badges()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only award badges when status changes to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Call the award_badges_on_completion function
    PERFORM award_badges_on_completion(NEW.user_id);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS trigger_award_badges ON user_projects;

-- Create trigger on user_projects table
CREATE TRIGGER trigger_award_badges
  AFTER UPDATE ON user_projects
  FOR EACH ROW
  WHEN (NEW.status = 'completed')
  EXECUTE FUNCTION auto_award_badges();

-- Grant permissions
GRANT EXECUTE ON FUNCTION auto_award_badges() TO authenticated, service_role;

-- Manually award badges for existing completed projects
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- For each user who has completed projects
  FOR v_user_id IN 
    SELECT DISTINCT user_id 
    FROM user_projects 
    WHERE status = 'completed'
  LOOP
    -- Award badges
    PERFORM award_badges_on_completion(v_user_id);
    RAISE NOTICE 'Awarded badges to user: %', v_user_id;
  END LOOP;
END $$;

-- Verify: Check if badges were awarded
SELECT 
  pr.name as user_name,
  b.name as badge_name,
  b.description,
  ub.awarded_at
FROM user_badges ub
JOIN badges b ON ub.badge_id = b.id
JOIN profiles pr ON ub.user_id = pr.id
ORDER BY ub.awarded_at DESC;

-- Also show user's completed projects count
SELECT 
  pr.name,
  COUNT(*) FILTER (WHERE up.status = 'completed') as completed_projects,
  COUNT(ub.id) as badges_earned
FROM profiles pr
LEFT JOIN user_projects up ON pr.id = up.user_id
LEFT JOIN user_badges ub ON pr.id = ub.user_id
GROUP BY pr.id, pr.name
HAVING COUNT(*) FILTER (WHERE up.status = 'completed') > 0;
