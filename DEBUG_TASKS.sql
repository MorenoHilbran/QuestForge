-- ============================================================
-- DEBUG: Check Tasks and User Assignment
-- ============================================================

-- 1. Check all tasks in the project
SELECT 
  t.title,
  t.status,
  t.priority,
  t.assigned_user_id,
  t.claimed_by_user_id,
  t.is_claimed,
  pr.name as assigned_to,
  prc.name as claimed_by
FROM tasks t
LEFT JOIN profiles pr ON t.assigned_user_id = pr.id
LEFT JOIN profiles prc ON t.claimed_by_user_id = prc.id
JOIN projects p ON t.project_id = p.id
WHERE p.title = 'QuestForge'
ORDER BY t.created_at;

-- 2. Check user_projects
SELECT 
  pr.name,
  up.role,
  up.progress,
  up.status
FROM user_projects up
JOIN profiles pr ON up.user_id = pr.id
JOIN projects p ON up.project_id = p.id
WHERE p.title = 'QuestForge';

-- 3. Count tasks by status
SELECT 
  status,
  COUNT(*) as count
FROM tasks t
JOIN projects p ON t.project_id = p.id
WHERE p.title = 'QuestForge'
GROUP BY status;
