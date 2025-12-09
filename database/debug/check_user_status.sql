-- Debug: Check user_projects status values
SELECT DISTINCT status FROM user_projects;

-- Check current user's projects (tanpa filter status)
SELECT 
  up.id,
  p.title as project_name,
  up.role,
  up.status,
  up.joined_at
FROM user_projects up
JOIN projects p ON up.project_id = p.id
WHERE up.user_id = auth.uid();

-- Check tasks in user's projects (tanpa filter status)
SELECT 
  p.title as project_name,
  t.title as task_title,
  t.assigned_role,
  t.status as task_status,
  up.role as my_role,
  up.status as my_project_status
FROM tasks t
JOIN projects p ON t.project_id = p.id
JOIN user_projects up ON t.project_id = up.project_id
WHERE up.user_id = auth.uid();
