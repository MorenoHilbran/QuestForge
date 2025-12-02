-- ============================================================
-- QUESTFORGE DATABASE SCHEMA - COMPLETE SETUP
-- ============================================================
-- Version: 2.0
-- Date: 2025-12-03
-- Description: Complete database schema dengan semua tables, 
--              RLS policies, triggers, functions, dan seed data
-- ============================================================

-- ============================================================
-- 1. ENABLE EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 2. DROP EXISTING TABLES (untuk clean install)
-- ============================================================
DROP TABLE IF EXISTS activity_logs CASCADE;
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS badges CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS milestones CASCADE;
DROP TABLE IF EXISTS user_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================================
-- 3. CREATE TABLES
-- ============================================================

-- 3.1 PROFILES TABLE
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3.2 PROJECTS TABLE
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  thumbnail_url TEXT,
  created_by_admin UUID REFERENCES profiles(id) ON DELETE CASCADE,
  mode TEXT DEFAULT 'solo' CHECK (mode IN ('solo', 'multiplayer')),
  required_roles TEXT[], -- Array of roles: ['frontend', 'backend', 'uiux', 'pm', 'fullstack']
  role_limits JSONB DEFAULT '{}'::jsonb, -- {"frontend": 2, "backend": 2, "uiux": 1, "pm": 1}
  max_members INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3.3 USER_PROJECTS TABLE (Junction table)
CREATE TABLE user_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  role TEXT, -- 'frontend', 'backend', 'uiux', 'pm', 'fullstack', 'solo'
  mode TEXT DEFAULT 'solo',
  progress DECIMAL(5,2) DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
  status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'dropped')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, project_id)
);

-- 3.4 TASKS TABLE
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  assigned_role TEXT, -- Role yang harus mengerjakan task ini
  due_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3.5 MILESTONES TABLE (Optional, for future use)
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3.6 BADGES TABLE
CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT NOT NULL,
  icon TEXT, -- Emoji or icon identifier
  category TEXT NOT NULL CHECK (category IN ('completion', 'difficulty', 'mode', 'role', 'special')),
  tier TEXT CHECK (tier IN ('bronze', 'silver', 'gold')),
  requirement_type TEXT NOT NULL, -- 'project_count', 'difficulty_count', 'mode_count', 'role_count'
  requirement_value INTEGER NOT NULL, -- Number required
  requirement_filter JSONB, -- Additional filters: {"difficulty": "hard", "mode": "solo"}
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3.7 USER_BADGES TABLE (Junction table)
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  awarded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

-- 3.8 ACTIVITY_LOGS TABLE (Optional, for tracking)
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL, -- 'joined_project', 'completed_task', 'earned_badge', etc.
  target_type TEXT, -- 'project', 'task', 'badge'
  target_id UUID,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 4. CREATE INDEXES
-- ============================================================
CREATE INDEX idx_projects_difficulty ON projects(difficulty);
CREATE INDEX idx_projects_mode ON projects(mode);
CREATE INDEX idx_user_projects_user_id ON user_projects(user_id);
CREATE INDEX idx_user_projects_project_id ON user_projects(project_id);
CREATE INDEX idx_user_projects_status ON user_projects(status);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_user_badges_user_id ON user_badges(user_id);

-- ============================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- 5.1 Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- 5.2 PROFILES Policies
CREATE POLICY "Authenticated users can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id OR auth.jwt()->>'role' = 'service_role');

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Service role has full access to profiles"
  ON profiles
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 5.3 PROJECTS Policies
CREATE POLICY "Anyone can view projects"
  ON projects FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can create projects"
  ON projects FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update their own projects"
  ON projects FOR UPDATE
  TO authenticated
  USING (created_by_admin = auth.uid());

CREATE POLICY "Admins can delete their own projects"
  ON projects FOR DELETE
  TO authenticated
  USING (created_by_admin = auth.uid());

-- 5.4 USER_PROJECTS Policies
CREATE POLICY "Authenticated users can view all user_projects"
  ON user_projects FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own user_projects"
  ON user_projects FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own user_projects"
  ON user_projects FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own user_projects"
  ON user_projects FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 5.5 TASKS Policies
CREATE POLICY "Users can view tasks in their projects"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_projects 
      WHERE user_projects.project_id = tasks.project_id 
      AND user_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create tasks in their projects"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_projects 
      WHERE user_projects.project_id = tasks.project_id 
      AND user_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update tasks in their projects"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_projects 
      WHERE user_projects.project_id = tasks.project_id 
      AND user_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own tasks"
  ON tasks FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- 5.6 BADGES Policies
CREATE POLICY "Anyone can view badges"
  ON badges FOR SELECT
  TO authenticated
  USING (true);

-- 5.7 USER_BADGES Policies
CREATE POLICY "Users can view all user_badges"
  ON user_badges FOR SELECT
  TO authenticated
  USING (true);

-- 5.8 ACTIVITY_LOGS Policies
CREATE POLICY "Users can view their own activity"
  ON activity_logs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- 6. FUNCTIONS
-- ============================================================

-- 6.1 Function: Auto-create profile for new users (OAuth & Email)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, avatar_url, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      SPLIT_PART(NEW.email, '@', 1)
    ),
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      NEW.raw_user_meta_data->>'picture'
    ),
    'user',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6.2 Function: Check and award badges based on achievements
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_badge_id UUID;
  v_badge_record RECORD;
  v_completed_count INTEGER;
  v_meets_requirement BOOLEAN;
BEGIN
  -- Get all completed projects for user
  SELECT COUNT(*) INTO v_completed_count
  FROM user_projects
  WHERE user_id = p_user_id AND status = 'completed';

  -- Loop through all badges
  FOR v_badge_record IN 
    SELECT * FROM badges
  LOOP
    v_meets_requirement := FALSE;
    
    -- Check based on requirement_type
    CASE v_badge_record.requirement_type
      WHEN 'project_count' THEN
        -- Check total completed projects
        IF v_completed_count >= v_badge_record.requirement_value THEN
          v_meets_requirement := TRUE;
        END IF;
        
      WHEN 'difficulty_count' THEN
        -- Check completed projects of specific difficulty
        SELECT COUNT(*) >= v_badge_record.requirement_value INTO v_meets_requirement
        FROM user_projects up
        JOIN projects p ON up.project_id = p.id
        WHERE up.user_id = p_user_id 
          AND up.status = 'completed'
          AND p.difficulty = v_badge_record.requirement_filter->>'difficulty';
          
      WHEN 'mode_count' THEN
        -- Check completed projects of specific mode
        SELECT COUNT(*) >= v_badge_record.requirement_value INTO v_meets_requirement
        FROM user_projects up
        JOIN projects p ON up.project_id = p.id
        WHERE up.user_id = p_user_id 
          AND up.status = 'completed'
          AND p.mode = v_badge_record.requirement_filter->>'mode';
          
      WHEN 'role_count' THEN
        -- Check completed projects with specific role
        SELECT COUNT(*) >= v_badge_record.requirement_value INTO v_meets_requirement
        FROM user_projects up
        WHERE up.user_id = p_user_id 
          AND up.status = 'completed'
          AND up.role = v_badge_record.requirement_filter->>'role';
    END CASE;
    
    -- Award badge if requirements met and not already awarded
    IF v_meets_requirement THEN
      INSERT INTO user_badges (user_id, badge_id, awarded_at)
      VALUES (p_user_id, v_badge_record.id, NOW())
      ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 6.3 Function: Update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 7. TRIGGERS
-- ============================================================

-- 7.1 Trigger: Auto-create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 7.2 Trigger: Update timestamps
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 8. SEED DATA - BADGES
-- ============================================================

INSERT INTO badges (name, description, icon, category, tier, requirement_type, requirement_value, requirement_filter)
VALUES
  -- Completion badges
  ('First Quest', 'Complete your first project', '🎯', 'completion', 'bronze', 'project_count', 1, NULL),
  ('Quest Master', 'Complete 5 projects', '⭐', 'completion', 'silver', 'project_count', 5, NULL),
  ('Legendary Quester', 'Complete 10 projects', '👑', 'completion', 'gold', 'project_count', 10, NULL),
  
  -- Difficulty badges
  ('Easy Conqueror', 'Complete 3 easy projects', '🌱', 'difficulty', 'bronze', 'difficulty_count', 3, '{"difficulty": "easy"}'),
  ('Medium Challenger', 'Complete 3 medium projects', '🔥', 'difficulty', 'silver', 'difficulty_count', 3, '{"difficulty": "medium"}'),
  ('Hard Achiever', 'Complete 3 hard projects', '💎', 'difficulty', 'gold', 'difficulty_count', 3, '{"difficulty": "hard"}'),
  
  -- Mode badges
  ('Solo Warrior', 'Complete 3 solo projects', '⚔️', 'mode', 'bronze', 'mode_count', 3, '{"mode": "solo"}'),
  ('Team Player', 'Complete 3 multiplayer projects', '🤝', 'mode', 'silver', 'mode_count', 3, '{"mode": "multiplayer"}'),
  
  -- Role badges
  ('Frontend Expert', 'Complete 5 projects as Frontend', '⚡', 'role', 'silver', 'role_count', 5, '{"role": "frontend"}'),
  ('Backend Master', 'Complete 5 projects as Backend', '✨', 'role', 'silver', 'role_count', 5, '{"role": "backend"}')
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- 9. GRANT PERMISSIONS
-- ============================================================
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, authenticated, service_role;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION check_and_award_badges(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION handle_new_user() TO service_role;

-- ============================================================
-- 10. VERIFICATION QUERIES
-- ============================================================

-- Check tables
SELECT 
  schemaname,
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check RLS policies
SELECT 
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check triggers
SELECT 
  trigger_name,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- Check functions
SELECT 
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- ============================================================
-- SETUP COMPLETE! 🎉
-- ============================================================
-- Next steps:
-- 1. Create admin user in Supabase Auth
-- 2. Update admin user role: UPDATE profiles SET role = 'admin' WHERE email = 'admin@example.com';
-- 3. Setup Google OAuth in Supabase Dashboard
-- 4. Configure redirect URLs for OAuth
-- 5. Test login and project creation!
-- ============================================================
