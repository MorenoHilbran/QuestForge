-- Check role yang digunakan untuk Project Manager
SELECT DISTINCT role 
FROM user_projects 
WHERE project_id IN (
  SELECT id FROM projects WHERE mode = 'multiplayer'
);

-- Check user yang login sebagai PM di project Larasena
SELECT 
  pr.name,
  pr.email,
  up.role,
  p.title as project_name
FROM user_projects up
JOIN profiles pr ON up.user_id = pr.id
JOIN projects p ON up.project_id = p.id
WHERE p.title = 'Larasena';
