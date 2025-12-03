-- ========================================
-- FIX: handle_new_user Trigger
-- ========================================
-- This fixes the trigger to handle edge cases where email might be null
-- and ensures name always has a fallback value

-- Drop and recreate the function with better null handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
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
        'User'  -- Ultimate fallback
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
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the function was updated
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'handle_new_user';

-- Test by checking if trigger exists
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- ========================================
-- NOTES
-- ========================================
/*
Changes made:
1. Added IF NEW.email IS NOT NULL check
2. Added 'User' as ultimate fallback for name
3. Ensured ON CONFLICT (id) DO NOTHING still works

This prevents errors when:
- Email is null (shouldn't happen in normal flow)
- Name metadata is missing
- Avatar URL is missing

All fields now have proper fallbacks:
- name: full_name → name → email prefix → 'User'
- email: NEW.email (required)
- avatar_url: avatar_url → picture → NULL (optional)
- role: 'user' (default)
*/
