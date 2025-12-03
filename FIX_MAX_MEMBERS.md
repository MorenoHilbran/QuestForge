# Fix: Max Members Calculation in Project Card

## Problem
Project card menampilkan jumlah maksimal user yang salah.

**Example Issue:**
- Frontend butuh: 2
- Backend butuh: 2  
- UI/UX butuh: 1
- **Total seharusnya**: 5 members
- **Yang muncul**: 0/8 Members ❌

## Root Cause
Project yang dibuat sebelum field `role_limits` ditambahkan tidak memiliki data `role_limits` di database, sehingga aplikasi menggunakan fallback calculation yang salah.

## Solution

### 1. Run SQL Migration (REQUIRED)

Jalankan script berikut di **Supabase SQL Editor**:

```bash
database/fixes/update_role_limits.sql
```

Script ini akan:
✅ Set `role_limits` default untuk semua project multiplayer
✅ Hitung otomatis dari `required_roles` (2 members per role)
✅ Set standard config untuk project tanpa `required_roles`

### 2. Code Fix (Already Applied)

**File: `lib/screens/home/home_screen.dart`**
- ✅ Improved calculation logic untuk sum role limits
- ✅ Better type handling (int, String, double)
- ✅ Fallback: estimate 2 members per role jika `role_limits` kosong
- ✅ Debug logging untuk troubleshooting

**File: `lib/data/models/project_model.dart`**
- ✅ Added `roleLimits` field
- ✅ Better error handling saat parsing JSON
- ✅ Debug logging untuk parsing errors

## How It Works

### Before Fix:
```
Database: role_limits = NULL atau {}
App Logic: Fallback ke jumlah required_roles
Result: 3 roles = max 3 members ❌
Display: "0/3 Members" (WRONG)
```

### After Fix:
```
Database: role_limits = {"frontend": 2, "backend": 2, "uiux": 1}
App Logic: Sum all role limits = 2+2+1 = 5
Result: max 5 members ✅
Display: "0/5 Members" (CORRECT)
```

## Testing

### 1. Check Database (Before)
```sql
SELECT 
    title,
    mode,
    required_roles,
    role_limits
FROM projects
WHERE mode = 'multiplayer';
```

Expected: Some projects have `role_limits` NULL or `{}`

### 2. Run Migration
Execute `update_role_limits.sql` in Supabase

### 3. Check Database (After)
```sql
SELECT 
    title,
    mode,
    role_limits,
    (SELECT SUM((value)::int) FROM jsonb_each_text(role_limits)) as max_members
FROM projects
WHERE mode = 'multiplayer';
```

Expected: All projects have `role_limits` populated

### 4. Test in App
1. Restart Flutter app
2. Go to Home screen
3. Check project cards
4. Expected: "X/Y Members" where Y = sum of role_limits

**Examples:**
- Frontend(2) + Backend(2) + UI/UX(1) = **0/5 Members** ✅
- Frontend(3) + Backend(3) + PM(1) = **0/7 Members** ✅
- Frontend(2) + Backend(2) = **0/4 Members** ✅

### 5. Check Debug Logs
Look for logs like:
```
Project: Project Name, roleLimits: {frontend: 2, backend: 2, uiux: 1}, calculated total: 5
```

## Common Scenarios

### Scenario 1: New Project (Created via Admin Panel)
- ✅ Admin sets role_limits in form
- ✅ Data saved to database
- ✅ Correct count displayed immediately

### Scenario 2: Old Project (Before role_limits feature)
- ❌ Database has role_limits = NULL
- ✅ Run migration SQL
- ✅ role_limits populated automatically
- ✅ Correct count displayed

### Scenario 3: Solo Project
- ✅ Always shows "1/1" (max 1 member)
- ✅ role_limits not needed for solo

## Standard Role Limits Configurations

**Small Team (4 members):**
```json
{
  "frontend": 2,
  "backend": 2
}
```

**Medium Team (6 members):**
```json
{
  "frontend": 2,
  "backend": 2,
  "uiux": 1,
  "pm": 1
}
```

**Large Team (8 members):**
```json
{
  "frontend": 3,
  "backend": 3,
  "uiux": 1,
  "pm": 1
}
```

## Manual Update (Alternative)

If you need to update specific project:

```sql
UPDATE projects
SET role_limits = '{
  "frontend": 2,
  "backend": 2,
  "uiux": 1,
  "pm": 1
}'::jsonb
WHERE id = 'project-id-here';
```

## Verification Queries

**Check all projects:**
```sql
SELECT 
    title,
    mode,
    role_limits,
    CASE 
        WHEN mode = 'solo' THEN 1
        WHEN role_limits IS NOT NULL THEN (
            SELECT SUM((value)::int) FROM jsonb_each_text(role_limits)
        )
        ELSE 0
    END as max_members
FROM projects
ORDER BY created_at DESC;
```

**Find projects needing update:**
```sql
SELECT title, mode, role_limits
FROM projects
WHERE mode = 'multiplayer'
  AND (role_limits IS NULL OR role_limits = '{}'::jsonb);
```

## Summary

**Problem**: ❌ Max members showing 0/8 instead of 0/5

**Cause**: Missing `role_limits` data in database

**Solution**: 
1. ✅ Run SQL migration: `update_role_limits.sql`
2. ✅ Code improvements already applied
3. ✅ Restart app to see changes

**Result**: ✅ Correct member count displayed (e.g., "0/5 Members")
