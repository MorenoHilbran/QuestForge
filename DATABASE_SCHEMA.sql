-- QuestForge Database Schema V2
-- Updated schema with Google OAuth, role system, and badge system

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. PROFILES TABLE (replaces users table)
-- ============================================================
-- This syncs with Supabase Auth users automatically
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  role TEXT DEFAULT 'user', -- 'admin' or 'user'
  badges JSONB DEFAULT '[]'::jsonb, -- Array of badge objects
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 2. PROJECTS TABLE
-- ============================================================
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT DEFAULT 'medium', -- 'easy', 'medium', 'hard'
  thumbnail_url TEXT,
  mode TEXT DEFAULT 'solo', -- 'solo' or 'multiplayer'
  required_roles TEXT[], -- Array of required roles for team projects: ['frontend', 'backend', 'uiux', 'pm', 'fullstack']
  role_limits JSONB DEFAULT '{}'::jsonb, -- Limit per role: {"frontend": 2, "backend": 2, "uiux": 1, "pm": 1}
  created_by_admin UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 3. USER_PROJECTS TABLE (project participation)
-- ============================================================
CREATE TABLE user_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  role TEXT NOT NULL, -- 'frontend', 'backend', 'uiux', 'pm', 'fullstack'
  mode TEXT DEFAULT 'multiplayer', -- 'solo' or 'multiplayer'
  progress NUMERIC(5,2) DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
  status TEXT DEFAULT 'in_progress', -- 'in_progress', 'completed', 'abandoned'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, project_id)
);

-- ============================================================
-- 4. MILESTONES TABLE
-- ============================================================
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed'
  required_role TEXT, -- which role should complete this milestone
  deadline TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 5. TASKS TABLE
-- ============================================================
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  milestone_id UUID REFERENCES milestones(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assigned_role TEXT, -- 'frontend', 'backend', 'uiux', 'pm', 'fullstack' - role yang ditugaskan untuk task ini
  status TEXT DEFAULT 'todo', -- 'todo', 'in_progress', 'review', 'done'
  priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high'
  deadline TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 6. ACTIVITY_LOGS TABLE
-- ============================================================
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action_type TEXT NOT NULL, -- 'task_created', 'milestone_completed', etc.
  message TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 7. BADGES TABLE (badge definitions)
-- ============================================================
CREATE TABLE badge_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT NOT NULL,
  icon_url TEXT,
  category TEXT NOT NULL, -- 'role', 'solo', 'team', 'meta'
  tier TEXT, -- 'junior', 'senior', 'master', 'legend'
  requirement JSONB NOT NULL, -- {role: 'frontend', count: 3} or {mode: 'solo', count: 5}
  is_unique BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_projects_admin ON projects(created_by_admin);
CREATE INDEX idx_user_projects_user ON user_projects(user_id);
CREATE INDEX idx_user_projects_project ON user_projects(project_id);
CREATE INDEX idx_user_projects_status ON user_projects(status);
CREATE INDEX idx_milestones_project ON milestones(project_id);
CREATE INDEX idx_tasks_milestone ON tasks(milestone_id);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assigned ON tasks(assigned_to);
CREATE INDEX idx_activity_logs_project ON activity_logs(project_id);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at DESC);

-- ============================================================
-- TRIGGERS FOR AUTO-UPDATE
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_milestones_updated_at BEFORE UPDATE ON milestones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TRIGGER: Auto-create profile on user signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- FUNCTION: Calculate project progress based on tasks
-- ============================================================
CREATE OR REPLACE FUNCTION calculate_project_progress(p_project_id UUID, p_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  total_tasks INTEGER;
  completed_tasks INTEGER;
  progress_percentage NUMERIC;
BEGIN
  SELECT COUNT(*) INTO total_tasks
  FROM tasks
  WHERE project_id = p_project_id AND assigned_to = p_user_id;
  
  IF total_tasks = 0 THEN
    RETURN 0;
  END IF;
  
  SELECT COUNT(*) INTO completed_tasks
  FROM tasks
  WHERE project_id = p_project_id 
    AND assigned_to = p_user_id 
    AND status = 'done';
  
  progress_percentage := (completed_tasks::NUMERIC / total_tasks::NUMERIC) * 100;
  
  -- Update user_projects table
  UPDATE user_projects
  SET progress = progress_percentage
  WHERE project_id = p_project_id AND user_id = p_user_id;
  
  RETURN progress_percentage;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCTION: Award badge to user
-- ============================================================
CREATE OR REPLACE FUNCTION award_badge(p_user_id UUID, p_badge_name TEXT)
RETURNS VOID AS $$
DECLARE
  badge_data JSONB;
BEGIN
  -- Get badge definition
  SELECT jsonb_build_object(
    'name', name,
    'description', description,
    'icon_url', icon_url,
    'category', category,
    'tier', tier,
    'awarded_at', NOW()
  ) INTO badge_data
  FROM badge_definitions
  WHERE name = p_badge_name;
  
  -- Check if user already has this badge
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = p_user_id 
      AND badges @> jsonb_build_array(jsonb_build_object('name', p_badge_name))
  ) THEN
    -- Add badge to user's collection
    UPDATE profiles
    SET badges = badges || jsonb_build_array(badge_data)
    WHERE id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCTION: Check and award badges based on achievements
-- ============================================================
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  role_record RECORD;
  solo_count INTEGER;
  team_count INTEGER;
  total_count INTEGER;
BEGIN
  -- Count completed projects by role
  FOR role_record IN
    SELECT role, COUNT(*) as count
    FROM user_projects
    WHERE user_id = p_user_id AND status = 'completed'
    GROUP BY role
  LOOP
    -- Award role-based badges
    CASE role_record.role
      WHEN 'frontend' THEN
        IF role_record.count >= 1 THEN PERFORM award_badge(p_user_id, 'Junior Frontend Developer'); END IF;
        IF role_record.count >= 3 THEN PERFORM award_badge(p_user_id, 'Senior Frontend Developer'); END IF;
        IF role_record.count >= 5 THEN PERFORM award_badge(p_user_id, 'Master of Interface'); END IF;
        IF role_record.count >= 10 THEN PERFORM award_badge(p_user_id, 'UI Samurai'); END IF;
      WHEN 'backend' THEN
        IF role_record.count >= 1 THEN PERFORM award_badge(p_user_id, 'Junior Backend Developer'); END IF;
        IF role_record.count >= 3 THEN PERFORM award_badge(p_user_id, 'Senior Backend Developer'); END IF;
        IF role_record.count >= 5 THEN PERFORM award_badge(p_user_id, 'API Architect'); END IF;
        IF role_record.count >= 10 THEN PERFORM award_badge(p_user_id, 'Database Overlord'); END IF;
      WHEN 'uiux' THEN
        IF role_record.count >= 1 THEN PERFORM award_badge(p_user_id, 'Junior UI/UX'); END IF;
        IF role_record.count >= 3 THEN PERFORM award_badge(p_user_id, 'Senior UI/UX'); END IF;
        IF role_record.count >= 5 THEN PERFORM award_badge(p_user_id, 'Wireframe Wizard'); END IF;
        IF role_record.count >= 10 THEN PERFORM award_badge(p_user_id, 'The Vision Crafter'); END IF;
      WHEN 'pm' THEN
        IF role_record.count >= 1 THEN PERFORM award_badge(p_user_id, 'Junior PM'); END IF;
        IF role_record.count >= 3 THEN PERFORM award_badge(p_user_id, 'Senior PM'); END IF;
        IF role_record.count >= 5 THEN PERFORM award_badge(p_user_id, 'Workflow Strategist'); END IF;
        IF role_record.count >= 10 THEN PERFORM award_badge(p_user_id, 'The Task Commander'); END IF;
    END CASE;
  END LOOP;
  
  -- Count solo mode completions
  SELECT COUNT(*) INTO solo_count
  FROM user_projects
  WHERE user_id = p_user_id AND status = 'completed' AND mode = 'solo';
  
  IF solo_count >= 1 THEN PERFORM award_badge(p_user_id, 'Lone Wolf'); END IF;
  IF solo_count >= 3 THEN PERFORM award_badge(p_user_id, 'Silent Operative'); END IF;
  IF solo_count >= 5 THEN PERFORM award_badge(p_user_id, 'One-Man Army'); END IF;
  IF solo_count >= 10 THEN PERFORM award_badge(p_user_id, 'Shadow Architect'); END IF;
  
  -- Count team mode completions
  SELECT COUNT(*) INTO team_count
  FROM user_projects
  WHERE user_id = p_user_id AND status = 'completed' AND mode = 'multiplayer';
  
  IF team_count >= 1 THEN PERFORM award_badge(p_user_id, 'Team Player'); END IF;
  IF team_count >= 3 THEN PERFORM award_badge(p_user_id, 'Squad Specialist'); END IF;
  IF team_count >= 5 THEN PERFORM award_badge(p_user_id, 'Synergy Maker'); END IF;
  IF team_count >= 10 THEN PERFORM award_badge(p_user_id, 'Guild Master'); END IF;
  
  -- Total projects
  SELECT COUNT(*) INTO total_count
  FROM user_projects
  WHERE user_id = p_user_id AND status = 'completed';
  
  IF total_count >= 20 THEN PERFORM award_badge(p_user_id, 'Quest Legend'); END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all, update only their own
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Projects: Everyone can view, only admins can create/update/delete
CREATE POLICY "Projects are viewable by everyone" ON projects FOR SELECT USING (true);
CREATE POLICY "Admins can insert projects" ON projects FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can update own projects" ON projects FOR UPDATE 
  USING (created_by_admin = auth.uid());
CREATE POLICY "Admins can delete own projects" ON projects FOR DELETE 
  USING (created_by_admin = auth.uid());

-- User Projects: Users can see their own, insert when joining, update progress
CREATE POLICY "Users can view own projects" ON user_projects FOR SELECT 
  USING (user_id = auth.uid());
CREATE POLICY "Users can join projects" ON user_projects FOR INSERT 
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own project progress" ON user_projects FOR UPDATE 
  USING (user_id = auth.uid());

-- Milestones: Viewable by project participants
CREATE POLICY "Milestones viewable by project members" ON milestones FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM user_projects 
    WHERE user_projects.project_id = milestones.project_id 
      AND user_projects.user_id = auth.uid()
  ));

-- Tasks: Viewable and updatable by assigned user or project admin
CREATE POLICY "Tasks viewable by project members" ON tasks FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM user_projects 
    WHERE user_projects.project_id = tasks.project_id 
      AND user_projects.user_id = auth.uid()
  ));
CREATE POLICY "Users can update assigned tasks" ON tasks FOR UPDATE 
  USING (assigned_to = auth.uid());

-- Activity logs: Viewable by project members
CREATE POLICY "Activity logs viewable by project members" ON activity_logs FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM user_projects 
    WHERE user_projects.project_id = activity_logs.project_id 
      AND user_projects.user_id = auth.uid()
  ));

-- Badge definitions: Public read
CREATE POLICY "Badge definitions are public" ON badge_definitions FOR SELECT USING (true);

-- ============================================================
-- SEED DATA: Badge Definitions
-- ============================================================
INSERT INTO badge_definitions (name, description, category, tier, requirement, is_unique) VALUES
-- Frontend badges
('Junior Frontend Developer', 'Complete 1 project as Frontend Developer', 'role', 'junior', '{"role": "frontend", "count": 1}'::jsonb, false),
('Senior Frontend Developer', 'Complete 3 projects as Frontend Developer', 'role', 'senior', '{"role": "frontend", "count": 3}'::jsonb, false),
('Master of Interface', 'Complete 5 projects as Frontend Developer', 'role', 'master', '{"role": "frontend", "count": 5}'::jsonb, false),
('UI Samurai', 'Complete 10 projects as Frontend Developer', 'role', 'legend', '{"role": "frontend", "count": 10}'::jsonb, true),

-- Backend badges
('Junior Backend Developer', 'Complete 1 project as Backend Developer', 'role', 'junior', '{"role": "backend", "count": 1}'::jsonb, false),
('Senior Backend Developer', 'Complete 3 projects as Backend Developer', 'role', 'senior', '{"role": "backend", "count": 3}'::jsonb, false),
('API Architect', 'Complete 5 projects as Backend Developer', 'role', 'master', '{"role": "backend", "count": 5}'::jsonb, false),
('Database Overlord', 'Complete 10 projects as Backend Developer', 'role', 'legend', '{"role": "backend", "count": 10}'::jsonb, true),

-- UI/UX badges
('Junior UI/UX', 'Complete 1 project as UI/UX Designer', 'role', 'junior', '{"role": "uiux", "count": 1}'::jsonb, false),
('Senior UI/UX', 'Complete 3 projects as UI/UX Designer', 'role', 'senior', '{"role": "uiux", "count": 3}'::jsonb, false),
('Wireframe Wizard', 'Complete 5 projects as UI/UX Designer', 'role', 'master', '{"role": "uiux", "count": 5}'::jsonb, false),
('The Vision Crafter', 'Complete 10 projects as UI/UX Designer', 'role', 'legend', '{"role": "uiux", "count": 10}'::jsonb, true),

-- Project Manager badges
('Junior PM', 'Complete 1 project as Project Manager', 'role', 'junior', '{"role": "pm", "count": 1}'::jsonb, false),
('Senior PM', 'Complete 3 projects as Project Manager', 'role', 'senior', '{"role": "pm", "count": 3}'::jsonb, false),
('Workflow Strategist', 'Complete 5 projects as Project Manager', 'role', 'master', '{"role": "pm", "count": 5}'::jsonb, false),
('The Task Commander', 'Complete 10 projects as Project Manager', 'role', 'legend', '{"role": "pm", "count": 10}'::jsonb, true),

-- Solo mode badges
('Lone Wolf', 'Complete 1 solo project', 'solo', 'junior', '{"mode": "solo", "count": 1}'::jsonb, false),
('Silent Operative', 'Complete 3 solo projects', 'solo', 'senior', '{"mode": "solo", "count": 3}'::jsonb, false),
('One-Man Army', 'Complete 5 solo projects', 'solo', 'master', '{"mode": "solo", "count": 5}'::jsonb, false),
('Shadow Architect', 'Complete 10 solo projects', 'solo', 'legend', '{"mode": "solo", "count": 10}'::jsonb, true),
('Perfect Execution', 'Complete solo project with 100% milestone completion', 'solo', 'master', '{"mode": "solo", "perfect": true}'::jsonb, true),

-- Team mode badges
('Team Player', 'Complete 1 team project', 'team', 'junior', '{"mode": "multiplayer", "count": 1}'::jsonb, false),
('Squad Specialist', 'Complete 3 team projects', 'team', 'senior', '{"mode": "multiplayer", "count": 3}'::jsonb, false),
('Synergy Maker', 'Complete 5 team projects', 'team', 'master', '{"mode": "multiplayer", "count": 5}'::jsonb, false),
('Guild Master', 'Complete 10 team projects', 'team', 'legend', '{"mode": "multiplayer", "count": 10}'::jsonb, true),
('Collaboration Champion', 'Active contribution in all milestones', 'team', 'master', '{"all_milestones": true}'::jsonb, true),

-- Meta achievements
('Versatile Adventurer', 'Complete at least 1 project in all roles', 'meta', 'master', '{"all_roles": true}'::jsonb, true),
('Quest Legend', 'Complete 20 projects total', 'meta', 'legend', '{"total": 20}'::jsonb, true),
('Consistency Over Chaos', 'Never absent more than 1 day', 'meta', 'master', '{"consistency": true}'::jsonb, true),
('Speed Runner', 'Complete project fastest in the system', 'meta', 'legend', '{"fastest": true}'::jsonb, true);
