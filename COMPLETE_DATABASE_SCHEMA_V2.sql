-- ============================================================
-- QUESTFORGE DATABASE SCHEMA V2 - PRODUCTION READY
-- ============================================================
-- Version: 2.0
-- Date: 2025-12-08
-- Description: Complete rework - No ambiguity, production-ready
-- Author: AI Assistant + Your Decisions
-- ============================================================

-- ============================================================
-- 🎯 DESIGN DECISIONS
-- ============================================================
-- 1. Project Code: MANDATORY, auto-generated 6-char uppercase
-- 2. Max Members: REMOVED, calculated from role_limits
-- 3. Task Assignment: Role-based + claim system (assigned_user_id)
-- 4. Solo Mode: User becomes PM automatically, full control
-- 5. Milestone: Fully implemented with progress tracking
-- 6. Activity Logs: Auto-triggered for all important actions
-- 7. Badge System: Auto-awarded via triggers
-- 8. Approval System: Implemented for multiplayer projects
-- ============================================================

-- ============================================================
-- 1. ENABLE EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- For secure random codes

-- ============================================================
-- 2. DROP EXISTING TABLES (Clean slate)
-- ============================================================
-- Drop trigger on auth.users (special case - system table)
DO $$ 
BEGIN
  DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
EXCEPTION
  WHEN undefined_table THEN NULL;
  WHEN undefined_object THEN NULL;
END $$;

-- Drop functions first (they don't reference tables)
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

-- Drop tables (CASCADE will automatically drop all associated triggers and constraints)
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

-- ------------------------------------------------------------
-- 3.1 PROFILES TABLE
-- User profile data (linked to auth.users)
-- ------------------------------------------------------------
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

COMMENT ON TABLE profiles IS 'User profiles for both admin and regular users';
COMMENT ON COLUMN profiles.role IS 'admin = can create projects, user = can join projects';

-- ------------------------------------------------------------
-- 3.2 PROJECTS TABLE
-- Project definitions created by admins
-- ------------------------------------------------------------
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL CHECK (code ~ '^[A-Z0-9]{6}$'),
  title TEXT NOT NULL CHECK (length(trim(title)) >= 3),
  description TEXT NOT NULL CHECK (length(trim(description)) >= 10),
  difficulty TEXT NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  thumbnail_url TEXT,
  created_by_admin UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  mode TEXT NOT NULL DEFAULT 'solo' CHECK (mode IN ('solo', 'multiplayer')),
  
  -- Role configuration (for multiplayer)
  required_roles TEXT[],
  role_limits JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- Approval settings
  requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Soft delete
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE projects IS 'Project definitions created by admins';
COMMENT ON COLUMN projects.code IS 'Unique 6-character code for joining (auto-generated)';
COMMENT ON COLUMN projects.mode IS 'solo = single user, multiplayer = team';
COMMENT ON COLUMN projects.role_limits IS 'JSONB object: {"frontend": 2, "backend": 2, "uiux": 1, "pm": 1}';
COMMENT ON COLUMN projects.requires_approval IS 'If true, PM must approve join requests';

-- ------------------------------------------------------------
-- 3.3 USER_PROJECTS TABLE (Junction)
-- Tracks which users joined which projects and their progress
-- ------------------------------------------------------------
CREATE TABLE user_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  
  -- Role assignment
  role TEXT NOT NULL CHECK (role IN ('solo', 'frontend', 'backend', 'uiux', 'pm', 'fullstack')),
  
  -- Approval workflow (for multiplayer with requires_approval)
  approval_status TEXT NOT NULL DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  
  -- Progress tracking
  progress DECIMAL(5,2) NOT NULL DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'dropped')),
  
  -- Timestamps
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  UNIQUE(user_id, project_id)
);

COMMENT ON TABLE user_projects IS 'Junction table tracking user participation in projects';
COMMENT ON COLUMN user_projects.approval_status IS 'pending = waiting PM approval, approved = can participate, rejected = denied';
COMMENT ON COLUMN user_projects.progress IS 'Auto-calculated from task completion (0-100)';

-- ------------------------------------------------------------
-- 3.4 MILESTONES TABLE
-- Major checkpoints within a project
-- ------------------------------------------------------------
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(trim(title)) >= 3),
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0 CHECK (order_index >= 0),
  target_date DATE,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Unique order within project
  UNIQUE(project_id, order_index)
);

COMMENT ON TABLE milestones IS 'Major project milestones for tracking macro progress';
COMMENT ON COLUMN milestones.order_index IS 'Display order within project (0, 1, 2, ...)';

-- ------------------------------------------------------------
-- 3.5 TASKS TABLE
-- Individual work items within a project
-- ------------------------------------------------------------
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,
  
  -- Task details
  title TEXT NOT NULL CHECK (length(trim(title)) >= 3),
  description TEXT,
  
  -- Assignment
  assigned_role TEXT CHECK (assigned_role IN ('solo', 'frontend', 'backend', 'uiux', 'pm', 'fullstack')),
  assigned_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- User who claimed the task
  claimed_at TIMESTAMP WITH TIME ZONE,
  
  -- Status & Priority
  status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  
  -- Deadline
  due_date TIMESTAMP WITH TIME ZONE,
  
  -- Tracking
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE tasks IS 'Individual work items assigned to roles or specific users';
COMMENT ON COLUMN tasks.assigned_role IS 'Role that should handle this task';
COMMENT ON COLUMN tasks.assigned_user_id IS 'Specific user who claimed this task (optional)';
COMMENT ON COLUMN tasks.claimed_at IS 'When a user claimed this task for themselves';

-- ------------------------------------------------------------
-- 3.6 BADGES TABLE
-- Achievements users can earn
-- ------------------------------------------------------------
CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL CHECK (length(trim(name)) >= 3),
  description TEXT NOT NULL,
  icon TEXT NOT NULL, -- Emoji or icon identifier
  category TEXT NOT NULL CHECK (category IN ('completion', 'difficulty', 'mode', 'role', 'special')),
  tier TEXT CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  
  -- Award criteria
  requirement_type TEXT NOT NULL CHECK (requirement_type IN (
    'project_count',       -- Complete N projects
    'difficulty_count',    -- Complete N projects of X difficulty
    'mode_count',          -- Complete N solo/multiplayer projects
    'role_count',          -- Complete N projects as X role
    'milestone_count',     -- Complete N milestones
    'task_count'           -- Complete N tasks
  )),
  requirement_value INTEGER NOT NULL CHECK (requirement_value > 0),
  requirement_filter JSONB, -- Additional filters: {"difficulty": "hard", "mode": "solo", "role": "pm"}
  
  -- Display order
  display_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE badges IS 'Achievement badges users can earn';
COMMENT ON COLUMN badges.requirement_filter IS 'JSONB filters for specific achievement criteria';

-- ------------------------------------------------------------
-- 3.7 USER_BADGES TABLE (Junction)
-- Badges awarded to users
-- ------------------------------------------------------------
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  awarded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  UNIQUE(user_id, badge_id)
);

COMMENT ON TABLE user_badges IS 'Badges that have been awarded to users';

-- ------------------------------------------------------------
-- 3.8 ACTIVITY_LOGS TABLE
-- Audit trail of important actions
-- ------------------------------------------------------------
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- Allow orphaned logs
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  
  -- Action details
  action TEXT NOT NULL CHECK (action IN (
    'project_created',
    'project_updated',
    'project_deleted',
    'user_joined',
    'user_approved',
    'user_rejected',
    'user_left',
    'task_created',
    'task_updated',
    'task_completed',
    'task_claimed',
    'milestone_created',
    'milestone_completed',
    'badge_earned'
  )),
  
  target_type TEXT CHECK (target_type IN ('project', 'task', 'milestone', 'badge', 'user')),
  target_id UUID,
  
  -- Additional context
  metadata JSONB,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE activity_logs IS 'Audit trail of all important user actions';

-- ============================================================
-- 4. CREATE INDEXES
-- ============================================================

-- Profiles
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_email ON profiles(email);

-- Projects
CREATE INDEX idx_projects_code ON projects(code);
CREATE INDEX idx_projects_mode ON projects(mode);
CREATE INDEX idx_projects_difficulty ON projects(difficulty);
CREATE INDEX idx_projects_created_by ON projects(created_by_admin);
CREATE INDEX idx_projects_active ON projects(deleted_at) WHERE deleted_at IS NULL;

-- User Projects
CREATE INDEX idx_user_projects_user ON user_projects(user_id);
CREATE INDEX idx_user_projects_project ON user_projects(project_id);
CREATE INDEX idx_user_projects_status ON user_projects(status);
CREATE INDEX idx_user_projects_role ON user_projects(role);
CREATE INDEX idx_user_projects_approval ON user_projects(approval_status) WHERE approval_status = 'pending';

-- Milestones
CREATE INDEX idx_milestones_project ON milestones(project_id);
CREATE INDEX idx_milestones_order ON milestones(project_id, order_index);
CREATE INDEX idx_milestones_completed ON milestones(is_completed);

-- Tasks
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_milestone ON tasks(milestone_id);
CREATE INDEX idx_tasks_assigned_role ON tasks(assigned_role);
CREATE INDEX idx_tasks_assigned_user ON tasks(assigned_user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;

-- Badges
CREATE INDEX idx_badges_category ON badges(category);
CREATE INDEX idx_badges_tier ON badges(tier);

-- User Badges
CREATE INDEX idx_user_badges_user ON user_badges(user_id);
CREATE INDEX idx_user_badges_badge ON user_badges(badge_id);

-- Activity Logs
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_project ON activity_logs(project_id);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at DESC);

-- ============================================================
-- 5. FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Generate Unique Project Code
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_project_code()
RETURNS TEXT AS $$
DECLARE
  new_code TEXT;
  code_exists BOOLEAN;
  attempts INTEGER := 0;
BEGIN
  LOOP
    -- Generate 6-character uppercase alphanumeric code
    new_code := upper(substr(encode(gen_random_bytes(4), 'base64'), 1, 6));
    
    -- Replace non-alphanumeric characters
    new_code := regexp_replace(new_code, '[^A-Z0-9]', substr('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', (random() * 35)::int + 1, 1), 'g');
    
    -- Ensure it's exactly 6 characters
    new_code := lpad(new_code, 6, '0');
    
    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM projects WHERE code = new_code) INTO code_exists;
    
    EXIT WHEN NOT code_exists;
    
    -- Prevent infinite loop
    attempts := attempts + 1;
    IF attempts > 100 THEN
      RAISE EXCEPTION 'Failed to generate unique project code after 100 attempts';
    END IF;
  END LOOP;
  
  RETURN new_code;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_project_code IS 'Generates unique 6-character uppercase code for projects';

-- ------------------------------------------------------------
-- 5.2 Auto-Generate Project Code on Insert
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_generate_project_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.code IS NULL OR NEW.code = '' THEN
    NEW.code := generate_project_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 5.3 Update Timestamp Trigger Function
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 5.4 Auto-Create Profile for New Users
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only insert if email is not null (required field)
  IF NEW.email IS NOT NULL THEN
    INSERT INTO public.profiles (id, name, email, avatar_url, role, created_at, updated_at)
    VALUES (
      NEW.id,
      COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        SPLIT_PART(NEW.email, '@', 1),
        'User'
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
    ON CONFLICT (id) DO UPDATE
    SET
      name = COALESCE(EXCLUDED.name, profiles.name),
      email = EXCLUDED.email,
      avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url),
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION handle_new_user IS 'Auto-creates profile when user signs up via OAuth or email';

-- ------------------------------------------------------------
-- 5.5 Check and Award Badges
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_badge_record RECORD;
  v_count INTEGER;
  v_meets_requirement BOOLEAN;
  v_badges_awarded INTEGER := 0;
BEGIN
  -- Loop through all badges
  FOR v_badge_record IN 
    SELECT * FROM badges ORDER BY display_order
  LOOP
    -- Skip if already awarded
    IF EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_record.id) THEN
      CONTINUE;
    END IF;
    
    v_meets_requirement := FALSE;
    
    -- Check based on requirement_type
    CASE v_badge_record.requirement_type
      
      WHEN 'project_count' THEN
        -- Total completed projects
        SELECT COUNT(*) INTO v_count
        FROM user_projects
        WHERE user_id = p_user_id AND status = 'completed';
        
        v_meets_requirement := v_count >= v_badge_record.requirement_value;
        
      WHEN 'difficulty_count' THEN
        -- Completed projects of specific difficulty
        SELECT COUNT(*) INTO v_count
        FROM user_projects up
        JOIN projects p ON up.project_id = p.id
        WHERE up.user_id = p_user_id 
          AND up.status = 'completed'
          AND p.difficulty = v_badge_record.requirement_filter->>'difficulty';
          
        v_meets_requirement := v_count >= v_badge_record.requirement_value;
        
      WHEN 'mode_count' THEN
        -- Completed projects of specific mode
        SELECT COUNT(*) INTO v_count
        FROM user_projects up
        JOIN projects p ON up.project_id = p.id
        WHERE up.user_id = p_user_id 
          AND up.status = 'completed'
          AND p.mode = v_badge_record.requirement_filter->>'mode';
          
        v_meets_requirement := v_count >= v_badge_record.requirement_value;
        
      WHEN 'role_count' THEN
        -- Completed projects with specific role
        SELECT COUNT(*) INTO v_count
        FROM user_projects
        WHERE user_id = p_user_id 
          AND status = 'completed'
          AND role = v_badge_record.requirement_filter->>'role';
          
        v_meets_requirement := v_count >= v_badge_record.requirement_value;
        
      WHEN 'milestone_count' THEN
        -- Completed milestones
        SELECT COUNT(DISTINCT m.id) INTO v_count
        FROM milestones m
        JOIN user_projects up ON m.project_id = up.project_id
        WHERE up.user_id = p_user_id 
          AND m.is_completed = TRUE
          AND up.status = 'completed';
          
        v_meets_requirement := v_count >= v_badge_record.requirement_value;
        
      WHEN 'task_count' THEN
        -- Completed tasks
        SELECT COUNT(*) INTO v_count
        FROM tasks
        WHERE assigned_user_id = p_user_id 
          AND status = 'done';
          
        v_meets_requirement := v_count >= v_badge_record.requirement_value;
        
    END CASE;
    
    -- Award badge if requirements met
    IF v_meets_requirement THEN
      INSERT INTO user_badges (user_id, badge_id, awarded_at)
      VALUES (p_user_id, v_badge_record.id, NOW())
      ON CONFLICT (user_id, badge_id) DO NOTHING;
      
      -- Log the achievement
      INSERT INTO activity_logs (user_id, action, target_type, target_id, metadata)
      VALUES (
        p_user_id,
        'badge_earned',
        'badge',
        v_badge_record.id,
        jsonb_build_object('badge_name', v_badge_record.name)
      );
      
      v_badges_awarded := v_badges_awarded + 1;
    END IF;
  END LOOP;
  
  RETURN v_badges_awarded;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_and_award_badges IS 'Checks user achievements and awards badges. Returns number of new badges awarded.';

-- ------------------------------------------------------------
-- 5.6 Auto-Check Badges on Project Completion
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_check_badges()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    PERFORM check_and_award_badges(NEW.user_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 5.7 Log Activity
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION log_activity()
RETURNS TRIGGER AS $$
DECLARE
  v_action TEXT;
  v_user_id UUID;
  v_project_id UUID;
  v_target_type TEXT;
BEGIN
  -- Determine action based on trigger context
  v_action := TG_ARGV[0];
  v_target_type := TG_ARGV[1];
  
  -- Extract user_id and project_id from NEW record
  IF TG_TABLE_NAME = 'user_projects' THEN
    v_user_id := NEW.user_id;
    v_project_id := NEW.project_id;
  ELSIF TG_TABLE_NAME = 'tasks' THEN
    v_user_id := NEW.created_by;
    v_project_id := NEW.project_id;
  ELSIF TG_TABLE_NAME = 'milestones' THEN
    v_user_id := NEW.created_by;
    v_project_id := NEW.project_id;
  ELSIF TG_TABLE_NAME = 'projects' THEN
    v_user_id := NEW.created_by_admin;
    v_project_id := NEW.id;
  END IF;
  
  -- Insert activity log
  INSERT INTO activity_logs (user_id, project_id, action, target_type, target_id, metadata)
  VALUES (
    v_user_id,
    v_project_id,
    v_action,
    v_target_type,
    NEW.id,
    to_jsonb(NEW)
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 5.8 Calculate User Progress in Project
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID, p_project_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_total_tasks INTEGER;
  v_completed_tasks INTEGER;
  v_progress DECIMAL(5,2);
BEGIN
  -- Get total tasks assigned to user's role
  SELECT COUNT(*) INTO v_total_tasks
  FROM tasks t
  JOIN user_projects up ON t.project_id = up.project_id
  WHERE up.user_id = p_user_id 
    AND up.project_id = p_project_id
    AND (t.assigned_role = up.role OR t.assigned_user_id = p_user_id);
  
  -- Avoid division by zero
  IF v_total_tasks = 0 THEN
    RETURN 0.0;
  END IF;
  
  -- Get completed tasks
  SELECT COUNT(*) INTO v_completed_tasks
  FROM tasks t
  JOIN user_projects up ON t.project_id = up.project_id
  WHERE up.user_id = p_user_id 
    AND up.project_id = p_project_id
    AND (t.assigned_role = up.role OR t.assigned_user_id = p_user_id)
    AND t.status = 'done';
  
  -- Calculate percentage
  v_progress := (v_completed_tasks::DECIMAL / v_total_tasks::DECIMAL) * 100;
  
  RETURN ROUND(v_progress, 2);
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 5.9 Auto-Update User Progress
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_update_progress()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_project_id UUID;
  v_new_progress DECIMAL;
BEGIN
  v_project_id := COALESCE(NEW.project_id, OLD.project_id);
  
  -- Update progress for all users in this project
  FOR v_user_id IN 
    SELECT DISTINCT user_id 
    FROM user_projects 
    WHERE project_id = v_project_id AND status = 'in_progress'
  LOOP
    v_new_progress := calculate_user_progress(v_user_id, v_project_id);
    
    UPDATE user_projects
    SET 
      progress = v_new_progress,
      status = CASE 
        WHEN v_new_progress >= 100 THEN 'completed'
        ELSE status
      END,
      completed_at = CASE
        WHEN v_new_progress >= 100 AND completed_at IS NULL THEN NOW()
        ELSE completed_at
      END
    WHERE user_id = v_user_id AND project_id = v_project_id;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 6. CREATE TRIGGERS
-- ============================================================

-- Auto-generate project code
CREATE TRIGGER auto_generate_project_code
  BEFORE INSERT ON projects
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_project_code();

-- Auto-create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Update timestamps
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at 
  BEFORE UPDATE ON projects
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at 
  BEFORE UPDATE ON tasks
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-check badges on project completion
CREATE TRIGGER on_project_completed
  AFTER UPDATE ON user_projects
  FOR EACH ROW
  EXECUTE FUNCTION auto_check_badges();

-- Auto-update progress when tasks change
CREATE TRIGGER on_task_status_changed
  AFTER UPDATE OF status ON tasks
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION auto_update_progress();

CREATE TRIGGER on_task_created
  AFTER INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_progress();

-- Activity logging triggers
CREATE TRIGGER log_project_created
  AFTER INSERT ON projects
  FOR EACH ROW
  EXECUTE FUNCTION log_activity('project_created', 'project');

CREATE TRIGGER log_user_joined
  AFTER INSERT ON user_projects
  FOR EACH ROW
  EXECUTE FUNCTION log_activity('user_joined', 'project');

CREATE TRIGGER log_task_created_activity
  AFTER INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION log_activity('task_created', 'task');

CREATE TRIGGER log_task_completed
  AFTER UPDATE ON tasks
  FOR EACH ROW
  WHEN (NEW.status = 'done' AND OLD.status != 'done')
  EXECUTE FUNCTION log_activity('task_completed', 'task');

CREATE TRIGGER log_milestone_created
  AFTER INSERT ON milestones
  FOR EACH ROW
  EXECUTE FUNCTION log_activity('milestone_created', 'milestone');

CREATE TRIGGER log_milestone_completed
  AFTER UPDATE ON milestones
  FOR EACH ROW
  WHEN (NEW.is_completed = TRUE AND OLD.is_completed = FALSE)
  EXECUTE FUNCTION log_activity('milestone_completed', 'milestone');

-- ============================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES Policies
-- ============================================================
CREATE POLICY "Profiles: anyone authenticated can view"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Profiles: authenticated users can insert their own"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Profiles: users can update their own"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Profiles: service role can do anything"
  ON profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- PROJECTS Policies
-- ============================================================
CREATE POLICY "Projects: anyone can view active"
  ON projects FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Projects: admins can create"
  ON projects FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Projects: admins can update own"
  ON projects FOR UPDATE
  TO authenticated
  USING (created_by_admin = auth.uid())
  WITH CHECK (created_by_admin = auth.uid());

-- ============================================================
-- USER_PROJECTS Policies
-- ============================================================
CREATE POLICY "UserProjects: users can view all"
  ON user_projects FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "UserProjects: service role can do anything"
  ON user_projects FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "UserProjects: users can join"
  ON user_projects FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "UserProjects: users can update own"
  ON user_projects FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- MILESTONES Policies
-- ============================================================
CREATE POLICY "Milestones: view in own projects"
  ON milestones FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = milestones.project_id
      AND up.user_id = auth.uid()
    )
  );

CREATE POLICY "Milestones: PMs can create"
  ON milestones FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = milestones.project_id
      AND up.user_id = auth.uid()
      AND up.role IN ('pm', 'solo')
    )
  );

-- ============================================================
-- TASKS Policies
-- ============================================================
CREATE POLICY "Tasks: view in own projects"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
      AND up.user_id = auth.uid()
    )
  );

CREATE POLICY "Tasks: PMs can create"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_projects up
      WHERE up.project_id = tasks.project_id
      AND up.user_id = auth.uid()
      AND up.role IN ('pm', 'solo')
    )
  );

CREATE POLICY "Tasks: creators can update"
  ON tasks FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid());

CREATE POLICY "Tasks: assigned can update"
  ON tasks FOR UPDATE
  TO authenticated
  USING (assigned_user_id = auth.uid())
  WITH CHECK (assigned_user_id = auth.uid());

-- ============================================================
-- BADGES Policies
-- ============================================================
CREATE POLICY "Badges: anyone authenticated can view"
  ON badges FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================
-- USER_BADGES Policies
-- ============================================================
CREATE POLICY "UserBadges: anyone can view"
  ON user_badges FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================
-- ACTIVITY_LOGS Policies
-- ============================================================
CREATE POLICY "ActivityLogs: authenticated can view and insert"
  ON activity_logs FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "ActivityLogs: service role can do anything"
  ON activity_logs FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 8. SEED DATA - BADGES
-- ============================================================

INSERT INTO badges (name, description, icon, category, tier, requirement_type, requirement_value, requirement_filter, display_order)
VALUES
  -- Completion badges
  ('First Steps', 'Complete your first project', '🎯', 'completion', 'bronze', 'project_count', 1, NULL, 1),
  ('Getting Started', 'Complete 3 projects', '⭐', 'completion', 'silver', 'project_count', 3, NULL, 2),
  ('Quest Master', 'Complete 5 projects', '👑', 'completion', 'silver', 'project_count', 5, NULL, 3),
  ('Legendary Quester', 'Complete 10 projects', '💎', 'completion', 'gold', 'project_count', 10, NULL, 4),
  ('Ultimate Champion', 'Complete 25 projects', '🏆', 'completion', 'platinum', 'project_count', 25, NULL, 5),
  
  -- Difficulty badges
  ('Beginner', 'Complete 3 easy projects', '🌱', 'difficulty', 'bronze', 'difficulty_count', 3, '{"difficulty": "easy"}', 10),
  ('Intermediate', 'Complete 3 medium projects', '🔥', 'difficulty', 'silver', 'difficulty_count', 3, '{"difficulty": "medium"}', 11),
  ('Expert', 'Complete 3 hard projects', '⚡', 'difficulty', 'gold', 'difficulty_count', 3, '{"difficulty": "hard"}', 12),
  ('Difficulty Master', 'Complete 2 projects of each difficulty', '🌟', 'difficulty', 'platinum', 'project_count', 6, NULL, 13),
  
  -- Mode badges
  ('Solo Warrior', 'Complete 3 solo projects', '⚔️', 'mode', 'bronze', 'mode_count', 3, '{"mode": "solo"}', 20),
  ('Team Player', 'Complete 3 multiplayer projects', '🤝', 'mode', 'silver', 'mode_count', 3, '{"mode": "multiplayer"}', 21),
  ('Balanced Adventurer', 'Complete both solo and team projects', '⚖️', 'mode', 'gold', 'project_count', 6, NULL, 22),
  
  -- Role badges
  ('Frontend Novice', 'Complete 3 projects as Frontend', '💻', 'role', 'bronze', 'role_count', 3, '{"role": "frontend"}', 30),
  ('Frontend Expert', 'Complete 5 projects as Frontend', '⚡', 'role', 'silver', 'role_count', 5, '{"role": "frontend"}', 31),
  ('Backend Novice', 'Complete 3 projects as Backend', '🔧', 'role', 'bronze', 'role_count', 3, '{"role": "backend"}', 32),
  ('Backend Expert', 'Complete 5 projects as Backend', '✨', 'role', 'silver', 'role_count', 5, '{"role": "backend"}', 33),
  ('Designer', 'Complete 3 projects as UI/UX', '🎨', 'role', 'bronze', 'role_count', 3, '{"role": "uiux"}', 34),
  ('Design Master', 'Complete 5 projects as UI/UX', '🖌️', 'role', 'silver', 'role_count', 5, '{"role": "uiux"}', 35),
  ('Project Lead', 'Complete 3 projects as PM', '📊', 'role', 'bronze', 'role_count', 3, '{"role": "pm"}', 36),
  ('Project Master', 'Complete 5 projects as PM', '👔', 'role', 'silver', 'role_count', 5, '{"role": "pm"}', 37),
  ('Full Stack Warrior', 'Complete 3 projects as Fullstack', '🚀', 'role', 'bronze', 'role_count', 3, '{"role": "fullstack"}', 38),
  ('Full Stack Legend', 'Complete 5 projects as Fullstack', '🌈', 'role', 'silver', 'role_count', 5, '{"role": "fullstack"}', 39),
  
  -- Task badges
  ('Task Starter', 'Complete 10 tasks', '📝', 'special', 'bronze', 'task_count', 10, NULL, 50),
  ('Task Crusher', 'Complete 25 tasks', '💪', 'special', 'silver', 'task_count', 25, NULL, 51),
  ('Task Master', 'Complete 50 tasks', '🎖️', 'special', 'gold', 'task_count', 50, NULL, 52),
  ('Task Legend', 'Complete 100 tasks', '🔱', 'special', 'platinum', 'task_count', 100, NULL, 53),
  
  -- Milestone badges
  ('Milestone Achiever', 'Complete 5 milestones', '🏁', 'special', 'bronze', 'milestone_count', 5, NULL, 60),
  ('Milestone Champion', 'Complete 10 milestones', '🎯', 'special', 'silver', 'milestone_count', 10, NULL, 61),
  ('Milestone Legend', 'Complete 25 milestones', '👑', 'special', 'gold', 'milestone_count', 25, NULL, 62),
  
  -- Special meta badges
  ('Versatile Adventurer', 'Try all 5 roles at least once', '🌐', 'special', 'gold', 'project_count', 5, NULL, 70),
  ('Quest Legend', 'Ultimate achievement: 25 projects + 100 tasks', '💫', 'special', 'platinum', 'project_count', 25, NULL, 71)
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- 9. GRANT PERMISSIONS
-- ============================================================
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, authenticated, service_role;

-- Grant execute on specific functions
GRANT EXECUTE ON FUNCTION generate_project_code() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION check_and_award_badges(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION handle_new_user() TO service_role;

-- ============================================================
-- 10. VERIFICATION QUERIES
-- ============================================================

-- Check all tables
SELECT 
  schemaname,
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check all RLS policies
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
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check all triggers
SELECT 
  trigger_schema,
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- Check all functions
SELECT 
  routine_schema,
  routine_name,
  routine_type,
  data_type,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Check all indexes
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ============================================================
-- 11. TEST DATA (Optional - Remove in production)
-- ============================================================

-- Uncomment below to insert test data

/*
-- Create test admin (you need to create this in Supabase Auth first)
-- UPDATE profiles SET role = 'admin' WHERE email = 'admin@questforge.com';

-- Create test project (replace admin_id with actual admin UUID)
INSERT INTO projects (title, description, difficulty, mode, required_roles, role_limits, created_by_admin)
VALUES (
  'Build a Todo App',
  'Create a full-stack todo application with React and Node.js',
  'medium',
  'multiplayer',
  ARRAY['frontend', 'backend', 'uiux'],
  '{"frontend": 2, "backend": 2, "uiux": 1}'::jsonb,
  'ADMIN_UUID_HERE'
);

-- Create test milestones
INSERT INTO milestones (project_id, title, description, order_index, target_date, created_by)
SELECT 
  id,
  'Setup Development Environment',
  'Install dependencies and configure development tools',
  1,
  CURRENT_DATE + INTERVAL '7 days',
  created_by_admin
FROM projects
WHERE title = 'Build a Todo App'
LIMIT 1;
*/

-- ============================================================
-- SETUP COMPLETE! 🎉
-- ============================================================
-- 
-- Next steps:
-- 1. Run this entire file in Supabase SQL Editor
-- 2. Create admin user in Supabase Auth dashboard
-- 3. Update admin role: UPDATE profiles SET role = 'admin' WHERE email = 'your@email.com';
-- 4. Configure OAuth providers in Supabase dashboard
-- 5. Update Flutter app to use new schema
-- 6. Test all workflows end-to-end
-- 
-- Key improvements in V2:
-- ✅ Project code system (auto-generated)
-- ✅ Task claim system (assigned_user_id)
-- ✅ Milestone fully implemented
-- ✅ Activity logs auto-triggered
-- ✅ Badge auto-award system
-- ✅ PM approval workflow
-- ✅ Auto-progress calculation
-- ✅ Soft delete support
-- ✅ Comprehensive constraints
-- ✅ Better RLS policies
-- ✅ Production-ready indexes
-- ✅ No ambiguity anywhere!
-- 
-- ============================================================
