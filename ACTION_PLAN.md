# 🎯 QuestForge V2 - Action Plan

## 📦 What's Done ✅

### Database (Phase 1) - COMPLETE
✅ `COMPLETE_DATABASE_SCHEMA_V2.sql` - Production-ready schema  
✅ `DATABASE_V2_MIGRATION_GUIDE.md` - Detailed migration guide  
✅ `QUICKSTART_V2.md` - Quick reference for developers  
✅ `CHANGELOG_V2.md` - Complete changelog  

**Status:** Ready to deploy to Supabase! 🚀

---

## 🎬 What You Need To Do Next

### Immediate (Deploy Database)

#### 1. **Backup Current Database** (5 minutes)
```
1. Go to Supabase Dashboard
2. Database → Backups
3. Click "Create Manual Backup"
4. Wait for completion
```

#### 2. **Deploy V2 Schema** (2 minutes)
```
1. Open Supabase SQL Editor
2. Copy entire content of COMPLETE_DATABASE_SCHEMA_V2.sql
3. Paste and click "RUN"
4. Wait for success message
```

#### 3. **Create Admin User** (1 minute)
```sql
-- After signing up, run this:
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'your-admin@email.com';
```

#### 4. **Test Basic Operations** (5 minutes)
```sql
-- Test project code generation
INSERT INTO projects (title, description, difficulty, mode, created_by_admin)
VALUES ('Test Project', 'Testing V2 features', 'easy', 'solo', 'YOUR_ADMIN_UUID');

-- Check if code was generated
SELECT code, title FROM projects WHERE title = 'Test Project';
-- Should return 6-char code like "A3B7K2"

-- Test progress calculation trigger
INSERT INTO tasks (project_id, title, assigned_role, status, created_by)
VALUES ('project-uuid', 'Test Task', 'solo', 'todo', 'user-uuid');

-- Update task to done
UPDATE tasks SET status = 'done' WHERE title = 'Test Task';

-- Check if progress updated automatically
SELECT progress FROM user_projects WHERE project_id = 'project-uuid';
-- Should show calculated progress!
```

✅ **Database is now ready!**

---

## 🔄 What Needs Updating (Phase 2-4)

### Phase 2: Flutter Models (Estimated: 2-3 hours)

#### Files to Update:

**1. `lib/data/models/project_model.dart`**
```dart
// ADD:
final String code;
final bool requiresApproval;
final DateTime? deletedAt;

// REMOVE:
// final int? maxMembers;  // Delete this

// ADD method:
int get maxMembers {
  if (roleLimits == null) return 0;
  return roleLimits!.values.fold(0, (sum, limit) => sum + limit);
}
```

**2. `lib/data/models/task_model.dart`**
```dart
// ADD:
final String? assignedUserId;
final DateTime? claimedAt;
final String? milestoneId;

// ADD methods:
bool get isClaimed => assignedUserId != null;
bool get isClaimedByMe => assignedUserId == currentUserId;
```

**3. `lib/data/models/user_project_model.dart`**
```dart
// ADD:
final String approvalStatus;  // 'pending', 'approved', 'rejected'
final String? approvedBy;
final DateTime? approvedAt;

// ADD methods:
bool get isPending => approvalStatus == 'pending';
bool get isApproved => approvalStatus == 'approved';
bool get isRejected => approvalStatus == 'rejected';
```

**4. `lib/data/models/milestone_model.dart`**
```dart
// ADD:
final int orderIndex;
final DateTime? targetDate;
final String createdBy;
final DateTime? completedAt;
```

**5. `lib/data/models/activity_log_model.dart`** (Already exists, verify fields)

**6. `lib/core/constants/app_constants.dart`**
```dart
// ADD new action types:
static const List<String> activityActions = [
  'project_created',
  'user_joined',
  'task_created',
  'task_completed',
  'task_claimed',
  'milestone_created',
  'milestone_completed',
  'badge_earned',
];

// ADD approval statuses:
static const List<String> approvalStatuses = [
  'pending',
  'approved',
  'rejected',
];
```

---

### Phase 3: Services & Remove Manual Updates (Estimated: 2-3 hours)

#### Critical: Remove Manual Progress Calculation

**Find and Remove:**
```dart
// ❌ DELETE code like this:
Future<void> updateProgress(String projectId) async {
  final tasks = await getTasks(projectId);
  final completed = tasks.where((t) => t.status == 'done').length;
  final progress = (completed / tasks.length) * 100;
  
  await supabase.from('user_projects').update({
    'progress': progress,
  }).eq('project_id', projectId);
}

// ✅ Just update task status, progress updates automatically!
Future<void> updateTaskStatus(String taskId, String status) async {
  await supabase.from('tasks').update({'status': status}).eq('id', taskId);
  // Done! Trigger handles the rest.
}
```

#### Remove Manual Badge Award

**Find and Remove:**
```dart
// ❌ DELETE code like this:
if (projectCompleted) {
  await supabase.rpc('check_and_award_badges', {'p_user_id': userId});
}

// ✅ It happens automatically via trigger now!
```

#### Add New Services

**Create: `lib/services/project_code_service.dart`**
```dart
class ProjectCodeService {
  static Future<Project?> findByCode(String code) async {
    final response = await supabase
      .from('projects')
      .select()
      .eq('code', code)
      .maybeSingle();
    return response != null ? Project.fromJson(response) : null;
  }
}
```

**Create: `lib/services/task_claim_service.dart`**
```dart
class TaskClaimService {
  static Future<void> claimTask(String taskId, String userId) async {
    await supabase.from('tasks').update({
      'assigned_user_id': userId,
      'claimed_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }
  
  static Future<void> unclaimTask(String taskId) async {
    await supabase.from('tasks').update({
      'assigned_user_id': null,
      'claimed_at': null,
    }).eq('id', taskId);
  }
}
```

**Create: `lib/services/approval_service.dart`**
```dart
class ApprovalService {
  static Future<List<JoinRequest>> getPendingRequests(String projectId) async {
    final response = await supabase
      .from('user_projects')
      .select('*, profiles(*)')
      .eq('project_id', projectId)
      .eq('approval_status', 'pending');
    return response.map((json) => JoinRequest.fromJson(json)).toList();
  }
  
  static Future<void> approveRequest(String userProjectId, String approverId) async {
    await supabase.from('user_projects').update({
      'approval_status': 'approved',
      'approved_by': approverId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', userProjectId);
  }
  
  static Future<void> rejectRequest(String userProjectId, String approverId) async {
    await supabase.from('user_projects').update({
      'approval_status': 'rejected',
      'approved_by': approverId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', userProjectId);
  }
}
```

---

### Phase 4: UI Updates (Estimated: 4-5 hours)

#### 1. **Show Project Code** (30 minutes)

**Update: `lib/screens/admin/admin_manage_projects_screen.dart`**
```dart
// In project card or detail:
Text('Code: ${project.code}'),
IconButton(
  icon: Icon(Icons.copy),
  onPressed: () {
    Clipboard.setData(ClipboardData(text: project.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code ${project.code} copied!')),
    );
  },
)
```

#### 2. **Add "Join with Code" Screen** (1 hour)

**Create: `lib/screens/projects/join_with_code_screen.dart`**
```dart
class JoinWithCodeScreen extends StatelessWidget {
  final codeController = TextEditingController();
  
  Future<void> _joinProject(BuildContext context) async {
    final code = codeController.text.trim().toUpperCase();
    
    // Find project by code
    final project = await ProjectCodeService.findByCode(code);
    
    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code: $code')),
      );
      return;
    }
    
    // Navigate to role selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinProjectScreen(project: project),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join with Code')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Project Code',
                hintText: 'ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _joinProject(context),
              child: Text('Join Project'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 3. **Add "Claim Task" Button** (30 minutes)

**Update: `lib/screens/projects/project_detail_screen.dart`**
```dart
// In task list item:
if (!task.isClaimed && task.assignedRole == currentUserRole) {
  ElevatedButton.icon(
    onPressed: () async {
      await TaskClaimService.claimTask(task.id, currentUserId);
      setState(() {});  // Refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task claimed!')),
      );
    },
    icon: Icon(Icons.check_circle),
    label: Text('Claim Task'),
  )
} else if (task.isClaimedByMe) {
  Chip(
    label: Text('Assigned to you'),
    backgroundColor: Colors.green,
  )
} else if (task.isClaimed) {
  Text('Claimed by ${task.assignedUserName}')
}
```

#### 4. **Add PM Approval Screen** (1.5 hours)

**Create: `lib/screens/admin/pm_approval_screen.dart`**
```dart
class PMApprovalScreen extends StatefulWidget {
  final String projectId;
  
  @override
  State<PMApprovalScreen> createState() => _PMApprovalScreenState();
}

class _PMApprovalScreenState extends State<PMApprovalScreen> {
  List<JoinRequest> _pendingRequests = [];
  
  @override
  void initState() {
    super.initState();
    _loadRequests();
  }
  
  Future<void> _loadRequests() async {
    final requests = await ApprovalService.getPendingRequests(widget.projectId);
    setState(() => _pendingRequests = requests);
  }
  
  Future<void> _approve(String requestId) async {
    await ApprovalService.approveRequest(requestId, currentUserId);
    _loadRequests();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User approved!')),
    );
  }
  
  Future<void> _reject(String requestId) async {
    await ApprovalService.rejectRequest(requestId, currentUserId);
    _loadRequests();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User rejected')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Requests')),
      body: _pendingRequests.isEmpty
        ? Center(child: Text('No pending requests'))
        : ListView.builder(
            itemCount: _pendingRequests.length,
            itemBuilder: (context, index) {
              final request = _pendingRequests[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: request.userAvatarUrl != null
                    ? NetworkImage(request.userAvatarUrl!)
                    : null,
                  child: request.userAvatarUrl == null 
                    ? Text(request.userName[0]) 
                    : null,
                ),
                title: Text(request.userName),
                subtitle: Text('Role: ${request.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approve(request.id),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _reject(request.id),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
```

#### 5. **Add Milestone Management** (1.5 hours)

**Create: `lib/screens/projects/milestone_management_screen.dart`**
```dart
// Full CRUD for milestones
// - List milestones ordered by order_index
// - Add milestone button
// - Edit milestone
// - Delete milestone
// - Mark as completed
// - Drag to reorder
```

#### 6. **Add Activity Feed** (1 hour)

**Create: `lib/screens/projects/activity_feed_screen.dart`**
```dart
class ActivityFeedScreen extends StatelessWidget {
  final String projectId;
  
  Future<List<ActivityLog>> _loadActivity() async {
    final response = await supabase
      .from('activity_logs')
      .select('*, profiles(*)')
      .eq('project_id', projectId)
      .order('created_at', ascending: false)
      .limit(50);
    return response.map((json) => ActivityLog.fromJson(json)).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Activity')),
      body: FutureBuilder<List<ActivityLog>>(
        future: _loadActivity(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final activities = snapshot.data!;
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                leading: Icon(_getIconForAction(activity.action)),
                title: Text(_getMessageForAction(activity)),
                subtitle: Text(timeAgo(activity.createdAt)),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 📋 Priority Checklist

### Must Do (Blockers) 🔴
- [ ] Deploy V2 database to Supabase
- [ ] Update ProjectModel (remove maxMembers)
- [ ] Remove manual progress calculation code
- [ ] Show project code in admin UI

### Should Do (Important) 🟡
- [ ] Update TaskModel (add claim fields)
- [ ] Add "Join with Code" screen
- [ ] Add "Claim Task" button
- [ ] Update UserProjectModel (add approval fields)

### Nice To Have (Polish) 🟢
- [ ] Add PM approval screen
- [ ] Add milestone management
- [ ] Add activity feed
- [ ] Add badge notifications

---

## ⏱️ Time Estimates

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| **Database Deploy** | Backup, deploy, test | 15 minutes |
| **Models Update** | 5 model files | 2-3 hours |
| **Services Update** | Remove manual code, add new services | 2-3 hours |
| **UI Update** | 6 major UI changes | 4-5 hours |
| **Testing** | End-to-end testing | 2-3 hours |
| **Total** | Complete V2 migration | **10-14 hours** |

---

## 📞 Need Help?

### Quick References
- 📖 **Detailed Guide:** `DATABASE_V2_MIGRATION_GUIDE.md`
- 🚀 **Quick Start:** `QUICKSTART_V2.md`
- 📝 **Changelog:** `CHANGELOG_V2.md`
- 💾 **Schema:** `COMPLETE_DATABASE_SCHEMA_V2.sql`

### Common Issues
1. **"Progress not updating"** → Check if trigger exists
2. **"Code is null"** → Only new projects have codes
3. **"Can't see other members"** → Use `.select('*, profiles(*)')`
4. **"Badges not awarded"** → Only on project completion

---

## 🎯 Next Action

**Right Now:**
1. Open Supabase Dashboard
2. Create backup
3. Run `COMPLETE_DATABASE_SCHEMA_V2.sql`
4. Test with sample project

**Then:**
5. Update Flutter models (Phase 2)
6. Remove manual code (Phase 3)
7. Update UI (Phase 4)
8. Test everything (Phase 5)

---

**You got this! 🚀**

Let me know when you've deployed the database and I'll help with Phase 2!
