-- ============================================================
-- DEBUG: Test Leave Project
-- ============================================================
-- Test apakah user bisa delete user_projects mereka sendiri
-- ============================================================

-- 1. Check RLS policies untuk DELETE di user_projects
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'user_projects'
  AND cmd = 'DELETE';

-- 2. Check apakah ada user_projects untuk user tertentu
-- GANTI dengan user_id dan project_id yang sebenarnya
SELECT * FROM user_projects 
WHERE user_id = 'USER_ID_DISINI'  -- Ganti dengan user_id Renggo Pandora
  AND project_id = 'PROJECT_ID_DISINI'; -- Ganti dengan project_id Warungin

-- 3. Test manual delete (sebagai admin di SQL Editor)
-- DELETE FROM user_projects 
-- WHERE user_id = 'USER_ID_DISINI' 
--   AND project_id = 'PROJECT_ID_DISINI';
