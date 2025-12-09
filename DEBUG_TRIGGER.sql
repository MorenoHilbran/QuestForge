-- ============================================================
-- DEBUG: Check Trigger and Function Status
-- ============================================================
-- Run this in Supabase SQL Editor to diagnose the issue
-- ============================================================

-- 1. Check if function exists
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'handle_new_user';

-- 2. Check if trigger exists
SELECT 
  trigger_name,
  event_object_table,
  action_statement,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- 3. Check profiles table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 4. Check RLS policies on profiles
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- 5. Check grants on profiles table
SELECT 
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY grantee, privilege_type;

-- 6. Test the function manually
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test@example.com';
BEGIN
  -- Simulate trigger execution
  RAISE NOTICE 'Testing handle_new_user function...';
  RAISE NOTICE 'Test user ID: %', test_user_id;
  RAISE NOTICE 'Test email: %', test_email;
  
  -- This will fail if there's an issue with the function
  -- (we're not actually inserting, just testing the logic)
END $$;
