-- ============================================================
-- FIX: Allow Anonymous Users to Create Profile During Signup
-- ============================================================
-- Run this in Supabase SQL Editor after running PRODUCTION_READY_SCHEMA.sql
-- ============================================================

-- Drop existing insert policies for profiles
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_anon" ON profiles;

-- Create new policy that allows authenticated users to insert their own profile
CREATE POLICY "profiles_insert_own" ON profiles 
  FOR INSERT 
  TO authenticated 
  WITH CHECK (auth.uid() = id);

-- Create policy for anon users during signup (trigger needs this)
CREATE POLICY "profiles_insert_anon" ON profiles 
  FOR INSERT 
  TO anon 
  WITH CHECK (true);

-- Grant necessary permissions
GRANT INSERT ON profiles TO anon;
GRANT USAGE ON SCHEMA public TO anon;

-- Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;
