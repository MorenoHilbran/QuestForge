-- ============================================================
-- FIX NULL ROLE_LIMITS IN PROJECTS TABLE
-- ============================================================
-- Run this in Supabase SQL Editor if you created projects 
-- with null role_limits
-- ============================================================

-- Fix existing projects with NULL role_limits
UPDATE projects 
SET role_limits = '{}'::jsonb 
WHERE role_limits IS NULL;

-- For solo projects, role_limits is not used (can be empty)
-- For multiplayer projects, update manually with proper role limits
-- Example:
-- UPDATE projects 
-- SET role_limits = '{"frontend": 2, "backend": 2, "uiux": 1, "pm": 1}'::jsonb 
-- WHERE mode = 'multiplayer' AND role_limits = '{}'::jsonb;

-- Verify
SELECT id, title, mode, role_limits FROM projects ORDER BY created_at DESC;
