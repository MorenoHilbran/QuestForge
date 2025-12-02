-- Migration: Add assigned_role to tasks and role_limits to projects
-- Jalankan query ini di Supabase SQL Editor

-- 1. Tambah kolom assigned_role ke table tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_role TEXT;

-- 2. Tambah kolom role_limits ke table projects
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS role_limits JSONB DEFAULT '{}'::jsonb;

-- 3. Update existing projects dengan default role limits (opsional)
-- Contoh: set limit 2 untuk setiap role
UPDATE projects 
SET role_limits = '{"frontend": 2, "backend": 2, "uiux": 1, "pm": 1, "fullstack": 2}'::jsonb
WHERE role_limits = '{}'::jsonb AND mode = 'multiplayer';

-- 4. Buat index untuk performa
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_role ON tasks(assigned_role);

-- 5. Enable RLS (Row Level Security) untuk tasks jika belum
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 6. Drop existing policies jika ada (optional - hati-hati di production)
DROP POLICY IF EXISTS "Users can view tasks" ON tasks;
DROP POLICY IF EXISTS "Users can insert tasks" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks" ON tasks;

-- 7. Create RLS policies untuk tasks
-- Policy untuk SELECT (semua user yang join project bisa lihat tasks)
CREATE POLICY "Users can view tasks" ON tasks
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT user_id FROM user_projects WHERE project_id = tasks.project_id
    )
    OR 
    -- Admin bisa lihat semua tasks
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Policy untuk INSERT (user yang join project, PM, atau admin bisa create tasks)
CREATE POLICY "Users can insert tasks" ON tasks
  FOR INSERT
  WITH CHECK (
    -- User yang join project bisa create task (untuk solo mode)
    auth.uid() IN (
      SELECT user_id FROM user_projects WHERE project_id = tasks.project_id
    )
    OR 
    -- Admin bisa create task di semua project
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Policy untuk UPDATE (user yang join project atau admin bisa update)
CREATE POLICY "Users can update tasks" ON tasks
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT user_id FROM user_projects WHERE project_id = tasks.project_id
    )
    OR 
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Policy untuk DELETE (hanya admin atau creator yang bisa delete)
CREATE POLICY "Users can delete tasks" ON tasks
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Selesai! Kolom dan policies sudah ditambahkan.
