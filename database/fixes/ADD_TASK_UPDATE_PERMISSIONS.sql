-- ============================================================
-- ADD TASK UPDATE PERMISSIONS VIA RLS
-- ============================================================
-- Run this in Supabase SQL Editor to enable task status updates

-- Add claimed_by_user_id column if not exists (for task claiming)
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS claimed_by_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- Add is_claimed boolean column if not exists
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_claimed BOOLEAN DEFAULT FALSE;

-- Create RLS policy: Users can update task status if they claimed it or task assigned to their user
CREATE POLICY "Tasks: authenticated can update own tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    -- Task assigned to current user
    assigned_user_id = auth.uid()
    -- OR task claimed by current user
    OR claimed_by_user_id = auth.uid()
  )
  WITH CHECK (
    -- Task assigned to current user (can update status)
    assigned_user_id = auth.uid()
    -- OR task claimed by current user (can update status)
    OR claimed_by_user_id = auth.uid()
  );

-- Create RLS policy: Admin/PM can update any task in their project
CREATE POLICY "Tasks: pm can manage all tasks"
  ON tasks FOR ALL
  TO authenticated
  USING (
    project_id IN (
      SELECT project_id FROM user_projects 
      WHERE user_id = auth.uid() 
      AND (role = 'pm' OR role = 'fullstack')
    )
  )
  WITH CHECK (
    project_id IN (
      SELECT project_id FROM user_projects 
      WHERE user_id = auth.uid() 
      AND (role = 'pm' OR role = 'fullstack')
    )
  );

-- Create RLS policy: Service role (triggers) can update all tasks
CREATE POLICY "Tasks: service role can do anything"
  ON tasks FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Verify policies created
SELECT 
  trigger_name,
  event_object_table,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'tasks'
ORDER BY trigger_name;
