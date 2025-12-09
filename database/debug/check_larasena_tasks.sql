-- Cek semua user_projects dan tasks (tanpa auth.uid filter)
SELECT 
  pr.name as user_name,
  pr.email,
  p.title as project_name,
  up.role as user_role,
  up.status as project_status,
  COUNT(t.id) as total_tasks,
  COUNT(CASE WHEN t.assigned_role = up.role THEN 1 END) as matching_role_tasks,
  COUNT(CASE WHEN t.assigned_role IS NULL THEN 1 END) as unassigned_tasks
FROM user_projects up
JOIN profiles pr ON up.user_id = pr.id
JOIN projects p ON up.project_id = p.id
LEFT JOIN tasks t ON t.project_id = p.id
WHERE p.mode = 'multiplayer'
GROUP BY pr.name, pr.email, p.title, up.role, up.status
ORDER BY p.title, up.role;

-- Cek detail tasks di project Larasena
SELECT 
  t.title,
  t.assigned_role,
  t.status,
  p.title as project_name
FROM tasks t
JOIN projects p ON t.project_id = p.id
WHERE p.title = 'Larasena'
ORDER BY t.assigned_role, t.title;
