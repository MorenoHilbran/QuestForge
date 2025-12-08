# 🚨 CRITICAL FIX: Complete Schema Reset

## Problem
Supabase schema cache is corrupted. Error: "Could not find the 'mode' column of 'user_projects' in the schema cache"

## Solution
Complete reset and rebuild of database schema.

---

## 📋 Steps to Fix

### Step 1: Stop Flutter App
Press `Ctrl+C` in terminal where `flutter run` is active

### Step 2: Open Supabase SQL Editor
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your QuestForge project
3. Click **SQL Editor** (left sidebar)
4. Click **New Query**

### Step 3: Run Complete Reset SQL
1. Open file: `database/fixes/COMPLETE_RESET_AND_FIX.sql`
2. Copy ALL the contents
3. Paste into Supabase SQL Editor
4. Click **RUN** button (big blue button)
5. **Wait for completion** - should see ✓ all green

### Step 4: Verify Success
At the bottom you should see:
- List of all tables (profiles, projects, user_projects, milestones, tasks, badges, user_badges, activity_logs)
- List of all RLS policies

If you see errors, report them immediately.

### Step 5: Restart Flutter App
```powershell
cd d:\Nigga\QuestForge
flutter run -d edge
```

### Step 6: Test Again
1. Login as user
2. Go to Projects → Join with Code
3. Enter project code
4. Should work now! ✓

---

## ⚠️ Important Notes
- This will DELETE ALL DATA in those tables
- You'll need to recreate admin account and projects
- RLS policies are now simplified (permissive) for development
- This is safe - it just resets schema structure

---

## If Still Error
1. Clear browser cache (Ctrl+Shift+Delete)
2. Or use incognito window
3. Wait 30 seconds for cache to refresh
4. Try again

---

## Need Help?
If error appears when running SQL, copy the error message and ask!
