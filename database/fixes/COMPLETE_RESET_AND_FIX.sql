-- ============================================================
-- COMPLETE SCHEMA RESET AND REBUILD
-- ============================================================
-- Run this in Supabase SQL Editor to completely fix schema cache issues
-- This will drop ALL tables and rebuild from scratch with correct schema
-- ============================================================

-- ============================================================
-- STEP 1: DROP EXISTING TABLES (Clean slate)
-- ============================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS check_and_award_badges(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS generate_project_code() CASCADE;
DROP FUNCTION IF EXISTS auto_check_badges() CASCADE;
DROP FUNCTION IF EXISTS log_activity_function() CASCADE;
DROP FUNCTION IF EXISTS log_activity() CASCADE;
DROP FUNCTION IF EXISTS auto_update_progress() CASCADE;
DROP FUNCTION IF EXISTS calculate_user_progress(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS auto_generate_project_code() CASCADE;

DROP TABLE IF EXISTS activity_logs CASCADE;
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS badges CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS milestones CASCADE;
DROP TABLE IF EXISTS user_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================================
-- STEP 2: ENABLE EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- STEP 3: CREATE PROFILES TABLE
-- ============================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (length(trim(name)) >= 2),
  email TEXT UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  avatar_url TEXT,
  bio TEXT CHECK (length(bio) <= 500),
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 4: CREATE PROJECTS TABLE
-- ============================================================
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL CHECK (code ~ '^[A-Z0-9]{6}$'),
  title TEXT NOT NULL CHECK (length(trim(title)) >= 3),
  description TEXT NOT NULL CHECK (length(trim(description)) >= 10),
  difficulty TEXT NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  thumbnail_url TEXT,
  created_by_admin UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  mode TEXT NOT NULL DEFAULT 'solo' CHECK (mode IN ('solo', 'multiplayer')),
  required_roles TEXT[],
  role_limits JSONB NOT NULL DEFAULT '{}'::jsonb,
  requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 5: CREATE USER_PROJECTS TABLE
-- ============================================================
CREATE TABLE user_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('solo', 'frontend', 'backend', 'uiux', 'pm', 'fullstack')),
  approval_status TEXT NOT NULL DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  progress DECIMAL(5,2) NOT NULL DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'dropped')),
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, project_id)
);

-- ============================================================
-- STEP 6: CREATE MILESTONES TABLE
-- ============================================================
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(trim(title)) >= 3),
  description TEXT,
  due_date DATE,
  progress DECIMAL(5,2) NOT NULL DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 7: CREATE TASKS TABLE
-- ============================================================
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,
  title TEXT NOT NULL CHECK (length(trim(title)) >= 3),
  description TEXT,
  assigned_user_id UUID REFERENCES profiles(id),
  claimed_by_user_id UUID REFERENCES profiles(id),
  status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  is_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  due_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 8: CREATE BADGES TABLE
-- ============================================================
CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL CHECK (length(trim(name)) >= 2),
  description TEXT,
  icon_url TEXT,
  type TEXT NOT NULL CHECK (type IN ('completion', 'speed', 'collaboration', 'quality')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 9: CREATE USER_BADGES TABLE
-- ============================================================
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

-- ============================================================
-- STEP 10: CREATE ACTIVITY_LOGS TABLE
-- ============================================================
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 11: ENABLE RLS ON ALL TABLES
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 12: SIMPLE RLS POLICIES - PERMISSIVE FOR NOW
-- ============================================================

-- PROFILES
CREATE POLICY "Profiles: authenticated can read" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Profiles: users can update own" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "Profiles: service role can do anything" ON profiles FOR ALL TO service_role USING (true) WITH CHECK (true);

-- PROJECTS
CREATE POLICY "Projects: authenticated can read" ON projects FOR SELECT TO authenticated USING (true);
CREATE POLICY "Projects: admins can create" ON projects FOR INSERT TO authenticated WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));
CREATE POLICY "Projects: admins can update" ON projects FOR UPDATE TO authenticated USING (created_by_admin = auth.uid()) WITH CHECK (created_by_admin = auth.uid());
CREATE POLICY "Projects: service role can do anything" ON projects FOR ALL TO service_role USING (true) WITH CHECK (true);

-- USER_PROJECTS
CREATE POLICY "UserProjects: authenticated can read" ON user_projects FOR SELECT TO authenticated USING (true);
CREATE POLICY "UserProjects: users can insert" ON user_projects FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "UserProjects: users can update own" ON user_projects FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "UserProjects: service role can do anything" ON user_projects FOR ALL TO service_role USING (true) WITH CHECK (true);

-- MILESTONES
CREATE POLICY "Milestones: authenticated can read own project milestones" ON milestones FOR SELECT TO authenticated USING (project_id IN (SELECT id FROM projects));
CREATE POLICY "Milestones: admins can insert" ON milestones FOR INSERT TO authenticated WITH CHECK (project_id IN (SELECT id FROM projects WHERE created_by_admin = auth.uid()));
CREATE POLICY "Milestones: admins can update" ON milestones FOR UPDATE TO authenticated USING (project_id IN (SELECT id FROM projects WHERE created_by_admin = auth.uid())) WITH CHECK (project_id IN (SELECT id FROM projects WHERE created_by_admin = auth.uid()));
CREATE POLICY "Milestones: service role can do anything" ON milestones FOR ALL TO service_role USING (true) WITH CHECK (true);

-- TASKS
CREATE POLICY "Tasks: authenticated can read own project tasks" ON tasks FOR SELECT TO authenticated USING (project_id IN (SELECT id FROM projects));
CREATE POLICY "Tasks: authenticated can insert" ON tasks FOR INSERT TO authenticated WITH CHECK (project_id IN (SELECT id FROM projects));
CREATE POLICY "Tasks: authenticated can update" ON tasks FOR UPDATE TO authenticated USING (project_id IN (SELECT id FROM projects)) WITH CHECK (project_id IN (SELECT id FROM projects));
CREATE POLICY "Tasks: service role can do anything" ON tasks FOR ALL TO service_role USING (true) WITH CHECK (true);

-- BADGES
CREATE POLICY "Badges: authenticated can read" ON badges FOR SELECT TO authenticated USING (true);
CREATE POLICY "Badges: service role can do anything" ON badges FOR ALL TO service_role USING (true) WITH CHECK (true);

-- USER_BADGES
CREATE POLICY "UserBadges: authenticated can read" ON user_badges FOR SELECT TO authenticated USING (true);
CREATE POLICY "UserBadges: service role can insert" ON user_badges FOR INSERT TO service_role WITH CHECK (true);
CREATE POLICY "UserBadges: service role can do anything" ON user_badges FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ACTIVITY_LOGS
CREATE POLICY "ActivityLogs: authenticated can read" ON activity_logs FOR SELECT TO authenticated USING (true);
CREATE POLICY "ActivityLogs: service role can do anything" ON activity_logs FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================
-- STEP 13: CREATE TRIGGER FOR AUTO-PROFILE CREATION
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- STEP 14: VERIFY ALL TABLES AND POLICIES
-- ============================================================
SELECT 
  schemaname,
  tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verify all RLS policies are in place
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
