-- ============================================================
-- QUICK START: Paste ini langsung ke Supabase SQL Editor
-- ============================================================
-- Jangan perlu buka file, cukup copy-paste code ini

-- STEP 1: Drop everything
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

-- STEP 2: Create tables
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  difficulty TEXT NOT NULL DEFAULT 'medium',
  thumbnail_url TEXT,
  created_by_admin UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  mode TEXT NOT NULL DEFAULT 'solo',
  required_roles TEXT[],
  role_limits JSONB NOT NULL DEFAULT '{}'::jsonb,
  requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE user_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  approval_status TEXT NOT NULL DEFAULT 'approved',
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  progress DECIMAL(5,2) NOT NULL DEFAULT 0.0,
  status TEXT NOT NULL DEFAULT 'in_progress',
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, project_id)
);

CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  progress DECIMAL(5,2) NOT NULL DEFAULT 0.0,
  status TEXT NOT NULL DEFAULT 'in_progress',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  assigned_user_id UUID REFERENCES profiles(id),
  claimed_by_user_id UUID REFERENCES profiles(id),
  status TEXT NOT NULL DEFAULT 'todo',
  priority TEXT NOT NULL DEFAULT 'medium',
  is_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  due_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  icon_url TEXT,
  type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- STEP 3: Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- STEP 4: Create RLS policies (permissive for development)
CREATE POLICY "allow_all" ON profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON projects FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON user_projects FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON milestones FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON badges FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON user_badges FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON activity_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Service role (for triggers and backend operations)
CREATE POLICY "service_all" ON profiles FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_all" ON projects FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_all" ON user_projects FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_all" ON milestones FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_all" ON tasks FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_all" ON badges FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_all" ON user_badges FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_all" ON activity_logs FOR ALL TO service_role USING (true) WITH CHECK (true);

-- STEP 5: Create function to auto-generate project code
CREATE OR REPLACE FUNCTION generate_project_code()
RETURNS TEXT AS $$
DECLARE
  new_code TEXT;
  code_exists BOOLEAN;
BEGIN
  LOOP
    -- Generate random 6-character code (uppercase letters and numbers)
    new_code := upper(substring(md5(random()::text) from 1 for 6));
    
    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM projects WHERE code = new_code) INTO code_exists;
    
    -- If code doesn't exist, return it
    IF NOT code_exists THEN
      RETURN new_code;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate project code
CREATE OR REPLACE FUNCTION auto_generate_project_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.code IS NULL OR NEW.code = '' THEN
    NEW.code := generate_project_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_project_code
BEFORE INSERT ON projects
FOR EACH ROW
EXECUTE FUNCTION auto_generate_project_code();

-- STEP 6: Create trigger for auto-profile creation
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

-- Done!
SELECT 'Database reset complete! Tables:' as status;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
