# Badge System Setup & Testing Guide

## Quick Setup (3 Steps)

### Step 1: Create Test Badges
Run this in Supabase SQL Editor:
```sql
-- File: database/seeds/test_badge.sql
INSERT INTO badges (name, description, type, icon_url)
VALUES
  ('First Quest Complete', 'Congratulations! You completed your first project! 🎉', 'completion', '🎯')
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description;
```

### Step 2: Create Badge Award Function
Run this in Supabase SQL Editor:
```sql
-- File: database/functions/award_badges_simple.sql
-- (Copy entire file content)
```

### Step 3: Test It!
1. Login to app
2. Create a solo project (any difficulty)
3. Add at least 1 task
4. Mark task as done (checkbox)
5. Click "Mark Project as Completed" button
6. **You should see**: "🎯 Badge Unlocked: First Quest Complete! 🎉 Project completed!"

## How It Works

### Complete Project Flow:
1. User clicks "Mark Project as Completed"
2. System updates:
   - `user_projects.status` → 'completed'
   - `user_projects.completed_at` → now
   - `projects.status` → 'completed'
3. Calls `award_badges_on_completion(user_id)` function
4. Function checks:
   - Total completed projects (≥1 = First Quest)
   - Solo projects (≥3 = Solo Warrior)
   - Team projects (≥3 = Team Player)
   - Difficulty counts (≥3 each = Master badges)
5. Awards badge if criteria met (no duplicates)
6. Shows notification with badge icon

### Button Visibility
Complete button appears when:
- ✅ All tasks are marked 'done'
- ✅ Project status != 'completed'
- ✅ User is: PM, Admin, or Solo player

### Badge Tiers
- **Bronze**: First milestones (1-3 completions)
- **Silver**: Intermediate (5 completions)
- **Gold**: Expert (10+ completions)

## Badge List

### Completion Badges:
- 🎯 First Quest Complete (1 project)
- ⭐ Quest Master (5 projects)
- 👑 Legendary Quester (10 projects)

### Mode Badges:
- ⚔️ Solo Warrior (3 solo projects)
- 🤝 Team Player (3 team projects)

### Difficulty Badges:
- 🌱 Easy Master (3 easy)
- 🔥 Medium Master (3 medium)
- 💎 Hard Hero (3 hard)

## Testing Checklist
- [ ] SQL: Run test_badge.sql
- [ ] SQL: Run award_badges_simple.sql
- [ ] App: Create project
- [ ] App: Add task
- [ ] App: Complete task
- [ ] App: Click "Mark Project as Completed"
- [ ] Verify: Badge notification appears
- [ ] Profile: Check badges tab shows new badge

## Troubleshooting

**No badge appears:**
- Check badges table has "First Quest Complete"
- Check function exists: `SELECT * FROM pg_proc WHERE proname = 'award_badges_on_completion'`
- Check user_badges table for entry

**Error calling function:**
- Function might not exist → re-run award_badges_simple.sql
- RLS policies might block → check user_badges policies allow insert

**Button not showing:**
- Check all tasks status = 'done'
- Check project status != 'completed'
- Check user role (must be PM/Admin/Solo)
