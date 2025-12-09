-- ============================================================
-- CHECK: Badge System Status
-- ============================================================

-- 1. Check if badge data exists
SELECT id, name, description, type FROM badges ORDER BY name;

-- 2. Check if user has any badges
SELECT 
  ub.awarded_at,
  b.name as badge_name,
  b.description,
  pr.name as user_name
FROM user_badges ub
JOIN badges b ON ub.badge_id = b.id
JOIN profiles pr ON ub.user_id = pr.id
ORDER BY ub.awarded_at DESC;

-- 3. Check completed projects count for user
SELECT 
  pr.name,
  pr.email,
  COUNT(*) FILTER (WHERE up.status = 'completed') as completed_projects
FROM profiles pr
LEFT JOIN user_projects up ON pr.id = up.user_id
GROUP BY pr.id, pr.name, pr.email;

-- 4. Check if award_badges function exists
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%badge%';

-- 5. Check triggers related to badges
SELECT 
  trigger_name,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE action_statement LIKE '%badge%';
