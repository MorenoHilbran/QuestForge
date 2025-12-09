# QuestForge V2 Setup Guide

## Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK 3.0+
- Supabase account (free tier works)

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign in or create account
3. Click "New Project"
4. Fill in project details:
   - Name: `questforge` (or your preferred name)
   - Database Password: Choose a strong password (save it!)
   - Region: Choose closest to you
   - Pricing Plan: Free tier is fine

## Step 2: Deploy Database Schema V2

1. In your Supabase project dashboard, go to **SQL Editor**
2. Click **New Query**
3. Open `COMPLETE_DATABASE_SCHEMA_V2.sql` from this repository
4. Copy the entire contents (1,200+ lines)
5. Paste into Supabase SQL Editor
6. Click **Run** button (bottom right)
7. Wait for success message: "Success. No rows returned"

This will create:
- ✅ 8 tables (projects, tasks, user_projects, milestones, badges, user_badges, profiles, activity_logs)
- ✅ 8 functions (generate_project_code, check_and_award_badges, calculate_user_progress, etc.)
- ✅ 13 triggers (auto project codes, auto progress calculation, auto badge awards)
- ✅ 35+ RLS policies (security)
- ✅ 30+ indexes (performance)

## Step 3: Get Supabase Credentials

1. In Supabase dashboard, go to **Project Settings** (gear icon)
2. Navigate to **API** section
3. Copy these values:
   - **Project URL** (e.g., `https://abcdefg.supabase.co`)
   - **anon/public key** (under "Project API keys")

## Step 4: Configure Flutter App

### Option A: Using .env file (Recommended for Mobile/Desktop)

1. Create a `.env` file in the root of your project:
```bash
# .env file
SUPABASE_URL=https://YOUR_PROJECT_URL.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_DEBUG=false
```

2. Replace `YOUR_PROJECT_URL` and `your_anon_key_here` with actual values from Step 3

### Option B: Using dart-define (Recommended for Web)

When running the app for web:
```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT_URL.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key_here
```

## Step 5: Install Dependencies

```bash
flutter pub get
```

## Step 6: Run the App

### For Mobile (Android/iOS):
```bash
flutter run
```

### For Web:
```bash
flutter run -d chrome
```

Or use the PowerShell script:
```powershell
.\run_web.ps1
```

### For Desktop (Windows):
```bash
flutter run -d windows
```

## Step 7: Verify Database Setup

After launching the app:

1. **Register** a new account (email + password)
2. **Create** a new project
3. Verify that:
   - ✅ Project has auto-generated 6-character code
   - ✅ You can view the project code in project details
   - ✅ Progress shows 0% initially

## V2 Features to Test

### 1. Project Codes
- Every project gets a unique 6-character code (e.g., "A3X7K9")
- View code in project detail screen
- Copy code with one tap
- Join projects via "Join with Code" screen

### 2. Auto Progress Calculation
- No manual calculation needed
- Database automatically calculates progress from tasks
- Updates in real-time when tasks change status

### 3. Auto Badge Awards
- Badges automatically awarded when achievements completed
- Triggered by database, not app code
- Check profile to see earned badges

### 4. Task Claiming
- Unclaimed tasks show "Claim Task" button
- Click to claim and auto-move to "In Progress"
- Claimed tasks show "Claimed by you" badge

### 5. PM Approval Workflow
- Projects can require PM approval for new members
- Pending requests show in PM Approval Screen
- PM can approve/reject join requests

### 6. Activity Logs
- Automatic logging of 14 action types:
  - project_created, project_joined, task_created, task_claimed
  - task_completed, milestone_completed, badge_earned, etc.
- View activity feed in profile

## Troubleshooting

### "Supabase not initialized" Error
- Check that `.env` file exists in project root
- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct
- For web, use `--dart-define` flags

### "Row Level Security" Errors
- Make sure you ran the complete `COMPLETE_DATABASE_SCHEMA_V2.sql`
- Check that you're logged in (not anonymous)
- Verify RLS policies in Supabase dashboard

### Tasks Not Showing Progress
- Progress is auto-calculated by triggers
- Check that tasks have correct status: 'todo', 'in_progress', or 'done'
- Verify trigger `update_project_progress_trigger` exists in database

### Project Code Not Generated
- Check trigger `auto_generate_project_code_trigger` exists
- Verify function `generate_project_code()` exists
- Try creating a new project to test

### Badges Not Awarding
- Badges are auto-awarded by `check_and_award_badges` function
- Triggered when tasks/milestones complete
- Check `user_badges` table to see if badge was inserted

## Database Schema Documentation

See these files for detailed documentation:
- `COMPLETE_DATABASE_SCHEMA_V2.sql` - Full production schema
- Database structure includes:
  - **projects**: title, code, difficulty, mode, requires_approval
  - **tasks**: title, status, assigned_user_id, claimed_at, milestone_id
  - **user_projects**: approval_status, approved_by, approved_at, progress
  - **milestones**: title, is_completed, order_index, completed_at
  - **badges**: name, criteria, icon
  - **user_badges**: earned_at, progress
  - **profiles**: name, email, avatar_url, role
  - **activity_logs**: action, target_type, target_id, metadata

## Next Steps

After successful setup:

1. ✅ Create test projects (solo and multiplayer)
2. ✅ Test task creation and claiming
3. ✅ Test joining projects via code
4. ✅ Test PM approval workflow (if enabled)
5. ✅ Verify badges auto-award on completion
6. ✅ Check activity logs populate automatically

## Support

For issues or questions:
- Check Supabase logs in dashboard
- Review Flutter console output
- Verify database schema deployed correctly
- Check RLS policies are active

---

**V2 Changes Summary:**
- ✅ Auto-generated project codes
- ✅ Database-driven progress calculation
- ✅ Auto-awarded badges via triggers
- ✅ Task claiming system
- ✅ PM approval workflow
- ✅ Comprehensive activity logging
- ✅ 30+ indexes for performance
- ✅ 35+ RLS policies for security
