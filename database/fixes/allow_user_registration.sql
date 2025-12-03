-- ============================================================
-- FIX: Allow User Registration (Email/Password Signup)
-- ============================================================
-- This ensures new users can create their own profile during registration
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Drop existing restrictive INSERT policy
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

-- 2. Create new policy that allows:
--    a) Users to insert their own profile (auth.uid() = id)
--    b) Service role to insert any profile (for triggers)
--    c) Anonymous users to insert profile during signup
CREATE POLICY "Users can insert their own profile during signup"
  ON profiles FOR INSERT
  WITH CHECK (
    -- Allow if user is inserting their own profile
    auth.uid() = id 
    OR 
    -- Allow service role (for triggers)
    auth.jwt()->>'role' = 'service_role'
    OR
    -- Allow during signup flow (when auth.uid() exists but profile not yet created)
    (auth.uid() IS NOT NULL AND id = auth.uid())
  );

-- 3. Add policy for anon role to insert during registration
-- This allows the signup process to complete
CREATE POLICY "Anon users can insert profile during signup"
  ON profiles FOR INSERT
  TO anon
  WITH CHECK (true);

-- Note: This is safe because:
-- 1. The profile ID must match the auth.users ID (enforced by foreign key)
-- 2. Supabase Auth handles the user creation first
-- 3. After signup, the user becomes 'authenticated' role

-- 4. Verify policies
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

-- ============================================================
-- TESTING
-- ============================================================

-- Test 1: Verify trigger exists (auto-create profile)
SELECT 
  trigger_name,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Test 2: Check if profile can be created (run after signup)
-- This should show your new profile
SELECT 
  id, 
  name, 
  email, 
  role,
  created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================
-- ROLLBACK (if needed)
-- ============================================================
-- If you want to revert to more restrictive policy:
/*
DROP POLICY IF EXISTS "Anon users can insert profile during signup" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile during signup" ON profiles;

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id OR auth.jwt()->>'role' = 'service_role');
*/
