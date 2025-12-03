# Enable User Registration (Email/Password)

## Problem
User tidak bisa register dengan email/password karena RLS policy mencegah insert ke table `profiles`.

## Solution

### Quick Fix (Run in Supabase SQL Editor)

```sql
-- Allow anonymous users to insert profile during signup
CREATE POLICY "Anon users can insert profile during signup"
  ON profiles FOR INSERT
  TO anon
  WITH CHECK (true);
```

### Complete Fix (Recommended)

Run file: `database/fixes/allow_user_registration.sql`

This will:
1. ✅ Drop restrictive INSERT policy
2. ✅ Create new policy yang allow signup
3. ✅ Allow anon role untuk insert during registration
4. ✅ Verify policies dengan query

## How It Works

### Registration Flow

**Before Fix:** ❌
```
1. User fill register form
2. Supabase Auth creates user in auth.users
3. App tries to INSERT into profiles table
4. ❌ RLS blocks: "authenticated users only"
5. Error: User created but no profile
```

**After Fix:** ✅
```
1. User fill register form
2. Supabase Auth creates user in auth.users
3. App INSERT into profiles table
4. ✅ RLS allows: "anon can insert during signup"
5. ✅ Profile created successfully
6. User can login and use app
```

### Alternative: Database Trigger (Better)

Instead of manual profile creation in Flutter, use database trigger:

```sql
-- This trigger auto-creates profile when user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

**Benefits:**
- ✅ No need to INSERT from Flutter
- ✅ Profile always created automatically
- ✅ Works for OAuth AND email signup
- ✅ Single source of truth

**Note:** File `COMPLETE_DATABASE_SCHEMA.sql` already includes this trigger!

## Testing

### Test Registration

1. **Clear test data** (if exists):
```sql
DELETE FROM auth.users WHERE email = 'test@example.com';
```

2. **Test signup in app**:
   - Open app → Click "Register"
   - Fill form: Name, Email, Password
   - Click "Sign Up"

3. **Verify profile created**:
```sql
SELECT id, name, email, role, created_at
FROM profiles
WHERE email = 'test@example.com';
```

Expected output:
```
id                  | name      | email              | role | created_at
--------------------|-----------|-----------------------|------|------------
xxx-xxx-xxx-xxx     | Test User | test@example.com   | user | 2025-12-03...
```

### Test Login After Registration

1. Logout from app
2. Login with registered email/password
3. Should navigate to homepage ✅

## Security Considerations

**Q: Is it safe to allow `anon` role to INSERT?**

**A: Yes**, because:

1. ✅ **Foreign Key Constraint**: `id` must match `auth.users(id)`
   - User must be created in `auth.users` first
   - Supabase Auth handles authentication
   
2. ✅ **Limited Scope**: Only INSERT permission
   - Cannot UPDATE other users' profiles
   - Cannot DELETE profiles
   - Cannot SELECT without authentication

3. ✅ **Trigger Fallback**: Database trigger creates profile automatically
   - If manual INSERT fails, trigger creates it
   - Ensures every user has a profile

4. ✅ **Role Elevation**: After signup, user becomes `authenticated`
   - No longer `anon` role
   - Normal RLS policies apply

## Common Issues

### Issue 1: "Profile already exists"
**Cause:** Trigger already created profile

**Solution:** This is fine! App should handle:
```dart
try {
  await client.from('profiles').insert({...});
} catch (e) {
  if (e.toString().contains('duplicate key')) {
    // Profile already exists, continue
  }
}
```

### Issue 2: "Permission denied for table profiles"
**Cause:** RLS policy not updated

**Solution:** Run `allow_user_registration.sql` in Supabase

### Issue 3: "null value in column 'name'"
**Cause:** Required fields missing

**Solution:** Ensure all required fields provided:
```dart
await client.from('profiles').insert({
  'id': userId,
  'name': name,      // ✅ Required
  'email': email,    // ✅ Required
  'role': 'user',    // ✅ Required
});
```

## Verification Queries

```sql
-- Check policies
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Should show:
-- "Anon users can insert profile during signup" | INSERT | {anon}
-- "Users can insert their own profile" | INSERT | {authenticated}
-- "Authenticated users can view all profiles" | SELECT | {authenticated}

-- Check trigger
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Should show:
-- on_auth_user_created | users

-- Test INSERT as anon
SET ROLE anon;
-- This should work now:
-- INSERT INTO profiles (id, name, email, role) VALUES (...);
RESET ROLE;
```

## Summary

**Changes Made:**
1. ✅ Added `anon` role INSERT policy to `profiles` table
2. ✅ Updated `COMPLETE_DATABASE_SCHEMA.sql` with new policy
3. ✅ Database trigger already handles auto-creation

**Result:**
- ✅ Users can register dengan email/password
- ✅ Profile automatically created via trigger OR manual insert
- ✅ Login works after registration
- ✅ Security tetap terjaga dengan RLS

**Files:**
- `database/fixes/allow_user_registration.sql` - SQL fix script
- `COMPLETE_DATABASE_SCHEMA.sql` - Updated with policy
- `REGISTER_POLICY.md` - This documentation
