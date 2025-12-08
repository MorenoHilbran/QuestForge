-- ============================================================
-- ADD PROJECT CODE AUTO-GENERATE FUNCTION
-- ============================================================
-- Run this if you get error: "null value in column 'code'"

-- Function to generate random 6-character project code
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

-- Trigger function to auto-generate project code before insert
CREATE OR REPLACE FUNCTION auto_generate_project_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.code IS NULL OR NEW.code = '' THEN
    NEW.code := generate_project_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_auto_generate_project_code ON projects;

CREATE TRIGGER trigger_auto_generate_project_code
BEFORE INSERT ON projects
FOR EACH ROW
EXECUTE FUNCTION auto_generate_project_code();

-- Verify trigger created
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_generate_project_code';
