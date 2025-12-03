-- ========================================
-- UPDATE ROLE LIMITS FOR EXISTING PROJECTS
-- ========================================
-- This script sets default role_limits for multiplayer projects
-- that don't have role_limits configured yet.
--
-- Execute this in Supabase SQL Editor after adding role_limits feature
-- to ensure existing projects display correct max member counts.

-- Check current state (BEFORE UPDATE)
SELECT 
    id,
    title,
    mode,
    required_roles,
    role_limits,
    CASE 
        WHEN role_limits IS NULL THEN 'NULL'
        WHEN role_limits = '{}'::jsonb THEN 'Empty'
        ELSE 'Has Data'
    END as limits_status
FROM projects
WHERE mode = 'multiplayer'
ORDER BY created_at DESC;

-- ========================================
-- UPDATE 1: Set default role_limits based on required_roles
-- ========================================

-- For projects with required_roles but no role_limits
-- This creates limits with 2 members per role as default
UPDATE projects
SET role_limits = (
    SELECT jsonb_object_agg(role, 2)
    FROM unnest(required_roles) AS role
)
WHERE mode = 'multiplayer'
  AND required_roles IS NOT NULL
  AND array_length(required_roles, 1) > 0
  AND (role_limits IS NULL OR role_limits = '{}'::jsonb);

-- ========================================
-- UPDATE 2: Set standard role_limits for common configurations
-- ========================================

-- For multiplayer projects without required_roles or still empty
-- Use standard role distribution: Frontend(2) + Backend(2) + UI/UX(1) + PM(1) = 6 total
UPDATE projects
SET role_limits = '{
    "frontend": 2,
    "backend": 2,
    "uiux": 1,
    "pm": 1
}'::jsonb
WHERE mode = 'multiplayer'
  AND (role_limits IS NULL OR role_limits = '{}'::jsonb);

-- ========================================
-- UPDATE 3: Ensure solo projects have empty role_limits
-- ========================================

UPDATE projects
SET role_limits = '{}'::jsonb
WHERE mode = 'solo'
  AND role_limits IS NULL;

-- ========================================
-- VERIFICATION: Check results (AFTER UPDATE)
-- ========================================

SELECT 
    id,
    title,
    mode,
    required_roles,
    role_limits,
    -- Calculate total max members
    CASE 
        WHEN mode = 'solo' THEN 1
        WHEN role_limits IS NOT NULL AND role_limits != '{}'::jsonb THEN (
            SELECT SUM((value)::int)
            FROM jsonb_each_text(role_limits)
        )
        ELSE 0
    END as max_members
FROM projects
ORDER BY mode DESC, created_at DESC;

-- ========================================
-- ROLLBACK (if needed)
-- ========================================

-- Uncomment to reset all role_limits to NULL
-- UPDATE projects SET role_limits = NULL;

-- Uncomment to reset only empty role_limits
-- UPDATE projects SET role_limits = NULL WHERE role_limits = '{}'::jsonb;

-- ========================================
-- EXPECTED RESULTS
-- ========================================

-- After running this script:
-- 1. All multiplayer projects should have role_limits set
-- 2. Solo projects should have empty role_limits '{}'
-- 3. Max members calculation should show correct totals:
--    - Example: {"frontend": 2, "backend": 2, "uiux": 1} = 5 members
--    - Home screen should show "0/5 Members" instead of "0/8"

-- ========================================
-- NOTES
-- ========================================

/*
Common role_limits configurations:

Small Team (4 members):
{"frontend": 2, "backend": 2}

Medium Team (6 members):
{"frontend": 2, "backend": 2, "uiux": 1, "pm": 1}

Large Team (8 members):
{"frontend": 3, "backend": 3, "uiux": 1, "pm": 1}

Full Stack Team (5 members):
{"fullstack": 4, "pm": 1}

Custom Configuration:
{"frontend": 2, "backend": 2, "uiux": 1, "pm": 1, "fullstack": 1}
*/
