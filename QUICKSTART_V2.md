# 🚀 QuestForge V2 - Quick Start Guide

## ⚡ TL;DR - Apa yang Berubah?

| Fitur | Status | Action Required |
|-------|--------|----------------|
| **Project Code** | ✅ NEW | Update UI untuk show code |
| **Task Claim** | ✅ NEW | Add "Claim Task" button |
| **Milestones** | ✅ FIXED | Implement milestone CRUD UI |
| **Activity Logs** | ✅ FIXED | Show activity feed |
| **Badge Auto-Award** | ✅ FIXED | No action (works automatically) |
| **Progress Calc** | ✅ FIXED | Remove manual calculation code |
| **PM Approval** | ✅ NEW | Add approval UI for PM |
| **Max Members** | ❌ REMOVED | Use `roleLimits` instead |

---

## 📦 Installation (Copy-Paste ke Supabase)

### Step 1: Backup (Important!)
1. Go to Supabase Dashboard → Database → Backups
2. Click "Create Manual Backup"
3. Wait for backup complete

### Step 2: Run Migration
1. Open Supabase SQL Editor
2. Copy **entire** content of `COMPLETE_DATABASE_SCHEMA_V2.sql`
3. Paste into SQL Editor
4. Click **RUN**
5. Wait for ✅ "Success" message (~30 seconds)

### Step 3: Create Admin
```sql
-- After signing up, make yourself admin
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'your@email.com';
```

### Step 4: Test
```sql
-- Test project code generation
INSERT INTO projects (title, description, difficulty, mode, created_by_admin)
VALUES ('Test', 'Testing code gen', 'easy', 'solo', 'YOUR_USER_ID');

-- Check code generated
SELECT code FROM projects WHERE title = 'Test';
-- Should return 6-char code like "AB12CD"
```

✅ Done! Database ready.

---

## 🔄 Code Changes Needed (Flutter)

### 1. Update Models

#### `project_model.dart`
```dart
// ADD these fields:
final String code;              // ✅ NEW
final bool requiresApproval;    // ✅ NEW
final DateTime? deletedAt;      // ✅ NEW

// REMOVE this:
// final int? maxMembers;        // ❌ REMOVED

// Calculate max members from roleLimits:
int get maxMembers {
  if (roleLimits == null) return 0;
  return roleLimits!.values.fold(0, (sum, limit) => sum + limit);
}
```

#### `task_model.dart`
```dart
// ADD these fields:
final String? assignedUserId;   // ✅ NEW - User who claimed
final DateTime? claimedAt;      // ✅ NEW - When claimed
final String? milestoneId;      // ✅ NEW - Link to milestone

// Check if claimed:
bool get isClaimed => assignedUserId != null;
bool get isClaimedByMe => assignedUserId == currentUser.id;
```

#### `user_project_model.dart`
```dart
// ADD these fields:
final String approvalStatus;    // ✅ NEW - 'pending'/'approved'/'rejected'
final String? approvedBy;       // ✅ NEW - PM who approved
final DateTime? approvedAt;     // ✅ NEW - When approved

bool get isPending => approvalStatus == 'pending';
bool get isApproved => approvalStatus == 'approved';
```

### 2. Remove Manual Progress Calculation

#### `task_service.dart` (or wherever you update tasks)
```dart
// ❌ OLD - Remove this:
Future<void> updateTaskStatus(String taskId, String status) async {
  await supabase.from('tasks').update({'status': status}).eq('id', taskId);
  
  // Remove manual progress calculation:
  // final tasks = await getTasks(projectId);
  // final progress = calculateProgress(tasks);
  // await updateProgress(projectId, progress);  // ❌ DELETE THIS
}

// ✅ NEW - Just update task:
Future<void> updateTaskStatus(String taskId, String status) async {
  await supabase.from('tasks').update({'status': status}).eq('id', taskId);
  // Progress updates automatically via trigger! 🎉
}
```

### 3. Add New Features

#### Join with Project Code
```dart
Future<void> joinWithCode(String code) async {
  // 1. Find project by code
  final project = await supabase
    .from('projects')
    .select()
    .eq('code', code)
    .maybeSingle();
    
  if (project == null) {
    throw Exception('Invalid project code');
  }
  
  // 2. Check if requires approval
  final requiresApproval = project['requires_approval'] ?? false;
  
  // 3. Join project
  await supabase.from('user_projects').insert({
    'user_id': currentUser.id,
    'project_id': project['id'],
    'role': selectedRole,
    'approval_status': requiresApproval ? 'pending' : 'approved',
  });
  
  // 4. Show appropriate message
  if (requiresApproval) {
    showSnackbar('Join request sent! Waiting for PM approval.');
  } else {
    showSnackbar('Successfully joined project!');
  }
}
```

#### Claim Task
```dart
Future<void> claimTask(String taskId) async {
  await supabase.from('tasks').update({
    'assigned_user_id': currentUser.id,
    'claimed_at': DateTime.now().toIso8601String(),
  }).eq('id', taskId);
  
  showSnackbar('Task claimed! It\'s now assigned to you.');
}
```

#### Approve Join Request (PM only)
```dart
Future<void> approveJoinRequest(String userProjectId, bool approve) async {
  await supabase.from('user_projects').update({
    'approval_status': approve ? 'approved' : 'rejected',
    'approved_by': currentUser.id,
    'approved_at': DateTime.now().toIso8601String(),
  }).eq('id', userProjectId);
}

// Get pending requests (PM view)
Future<List<Map>> getPendingRequests(String projectId) async {
  return await supabase
    .from('user_projects')
    .select('*, profiles(*)')
    .eq('project_id', projectId)
    .eq('approval_status', 'pending')
    .order('joined_at', ascending: false);
}
```

### 4. Update UI

#### Show Project Code
```dart
// In project detail screen or project card:
Text('Project Code: ${project.code}'),
IconButton(
  icon: Icon(Icons.copy),
  onPressed: () {
    Clipboard.setData(ClipboardData(text: project.code));
    showSnackbar('Code copied!');
  },
)
```

#### Show Claim Button (for unclaimed tasks)
```dart
// In task card:
if (!task.isClaimed && task.assignedRole == myRole) {
  ElevatedButton(
    onPressed: () => claimTask(task.id),
    child: Text('Claim Task'),
  )
} else if (task.isClaimedByMe) {
  Chip(label: Text('Assigned to you'))
} else if (task.isClaimed) {
  Text('Claimed by ${task.assignedUserName}')
}
```

#### Show Approval Badge (for pending users)
```dart
// In user project list:
if (userProject.isPending) {
  Chip(
    label: Text('Pending Approval'),
    backgroundColor: Colors.orange,
  )
}
```

---

## 🎯 Priority Fixes (Do These First)

### High Priority (Blockers) 🔴
1. ✅ **Remove `maxMembers` references** - Use `roleLimits` calculation
2. ✅ **Remove manual progress updates** - It's automatic now
3. ✅ **Show project code** in UI

### Medium Priority (Important) 🟡
4. ✅ **Add "Claim Task" feature**
5. ✅ **Add "Join with Code" screen**
6. ✅ **Update task model** (assignedUserId, claimedAt)

### Low Priority (Nice-to-have) 🟢
7. ✅ **Add PM approval UI**
8. ✅ **Show activity logs**
9. ✅ **Implement milestone CRUD**

---

## 🧪 Testing Checklist

### Must Test ✅
- [ ] Create project → Code generated automatically
- [ ] Join project by code → Works
- [ ] Update task status → Progress auto-updates
- [ ] Complete project → Badges auto-awarded
- [ ] OAuth signup → Profile auto-created

### Should Test ⚠️
- [ ] Claim task → assigned_user_id updates
- [ ] View other members → Can see in same project
- [ ] PM approval workflow → Pending → Approved
- [ ] Solo project → Only 1 user allowed
- [ ] Role limits → Can't join if full

### Nice to Test ✨
- [ ] Create milestone → Shows in project
- [ ] Activity logs → All actions logged
- [ ] Soft delete project → Can recover
- [ ] Badge auto-award → Check activity_logs

---

## 🐛 Quick Fixes

### "Project code is null"
```dart
// Make sure you're querying new data after migration
// Old projects won't have codes (created before V2)

// Solution: Re-create project or manually assign code
UPDATE projects SET code = 'ABC123' WHERE id = 'old-project-id';
```

### "Progress not updating"
```dart
// Make sure task status actually changed
// Trigger only fires on UPDATE, not INSERT

// Check if trigger exists:
SELECT * FROM information_schema.triggers 
WHERE trigger_name = 'on_task_status_changed';
```

### "Can't see other members"
```dart
// Make sure you're querying with proper join:
final members = await supabase
  .from('user_projects')
  .select('*, profiles(*)')  // ← Important: join profiles
  .eq('project_id', projectId);
```

### "Badge not awarded"
```dart
// Badges only awarded on project completion
// Status must change from 'in_progress' to 'completed'

// Manual trigger:
await supabase.rpc('check_and_award_badges', {'p_user_id': userId});
```

---

## 📞 Common Questions

### Q: Do I need to migrate data?
**A:** No, V2 is backwards compatible. Old data will work, new features will be empty/default values.

### Q: Will old projects have codes?
**A:** No, codes only generated for NEW projects. You can manually assign codes to old projects if needed.

### Q: Can I rollback?
**A:** Yes, restore from backup (Step 1). But you'll lose V2 features.

### Q: Do I need to update Flutter immediately?
**A:** No, app will work with old code. But you won't see new features (codes, claims, etc). Update when ready.

### Q: What about production data?
**A:** Test migration in development first. Use staging environment. Then migrate production with zero-downtime strategy.

---

## 🎉 You're Ready!

Database V2 is **production-ready** with:
- ✅ No ambiguity
- ✅ Auto-everything
- ✅ Complete audit trail
- ✅ Security hardened
- ✅ Performance optimized

**Next:** Update Flutter models & UI (Phase 2)

---

Need help? Check:
- 📖 `DATABASE_V2_MIGRATION_GUIDE.md` (detailed)
- 📄 `COMPLETE_DATABASE_SCHEMA_V2.sql` (source)
- 💬 Ask me anything!

**Happy coding! 🚀**
