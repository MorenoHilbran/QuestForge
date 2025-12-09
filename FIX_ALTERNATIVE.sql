-- ============================================================
-- ALTERNATIVE FIX: Temporarily Disable RLS for Signup
-- ============================================================
-- If SECURITY DEFINER doesn't work, we disable RLS entirely
-- for the trigger function execution
-- ============================================================

-- Method 1: Alter existing function to run as postgres
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- Method 2: Check current auth.users table for any failed inserts
SELECT id, email, created_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- Method 3: Check if there are orphaned users (in auth.users but not in profiles)
SELECT 
  u.id,
  u.email,
  u.created_at,
  p.id IS NULL as missing_profile
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
ORDER BY u.created_at DESC
LIMIT 10;

-- Method 4: Nuclear option - Temporarily disable RLS on profiles for testing
-- WARNING: Only use this temporarily for testing!
-- ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Then re-enable after signup works:
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
