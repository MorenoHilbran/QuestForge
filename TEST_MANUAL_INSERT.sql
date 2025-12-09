-- ============================================================
-- TEST: Manually Test Trigger Function
-- ============================================================
-- Test if the trigger function can actually insert into profiles
-- ============================================================

-- First, check existing profiles
SELECT COUNT(*) as total_profiles FROM profiles;

-- Try to manually create a test profile using the same logic as trigger
DO $$
DECLARE
  test_id UUID := gen_random_uuid();
  test_email TEXT := 'manual_test@example.com';
  test_name TEXT := 'Manual Test';
BEGIN
  RAISE NOTICE 'Attempting to insert test profile...';
  RAISE NOTICE 'ID: %', test_id;
  RAISE NOTICE 'Email: %', test_email;
  
  INSERT INTO public.profiles (id, name, email, role, created_at, updated_at)
  VALUES (
    test_id,
    test_name,
    test_email,
    'user',
    NOW(),
    NOW()
  );
  
  RAISE NOTICE 'SUCCESS! Profile inserted.';
  
  -- Clean up test data
  DELETE FROM public.profiles WHERE id = test_id;
  RAISE NOTICE 'Test profile deleted.';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'ERROR: %', SQLERRM;
  RAISE NOTICE 'DETAIL: %', SQLSTATE;
END $$;

-- Check Supabase Auth configuration
-- See if email confirmation is required
SELECT 
  name,
  value
FROM pg_settings
WHERE name LIKE '%auth%'
ORDER BY name;
