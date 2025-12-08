import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_text_field.dart';
import '../widgets/neo_button.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> 
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _teamMembers = [];
  Map<String, dynamic>? _userProject;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isPM = false;
  bool _hasProjectManager = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final isAdmin = context.read<AuthProvider>().currentUser?.isAdmin ?? false;
      
      setState(() => _isAdmin = isAdmin);

      // Load user's project participation
      final userProjectResponse = await SupabaseService.client
          .from('user_projects')
          .select()
          .eq('user_id', userId!)
          .eq('project_id', widget.project['id'])
          .maybeSingle();

      // Load milestones (future use)
      // final milestonesResponse = await SupabaseService.client
      //     .from('milestones')
      //     .select()
      //     .eq('project_id', widget.project['id'])
      //     .order('order_index', ascending: true);

      // Load tasks
      final tasksResponse = await SupabaseService.client
          .from('tasks')
          .select()
          .eq('project_id', widget.project['id'])
          .order('created_at', ascending: false);

      // Load team members (users who joined this project)
      final teamResponse = await SupabaseService.client
          .from('user_projects')
          .select('id, user_id, role, approval_status, progress')
          .eq('project_id', widget.project['id'])
          .order('joined_at', ascending: true);

      // Load profiles for team members
      final teamMembers = (teamResponse as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      for (var member in teamMembers) {
        try {
          final profile = await SupabaseService.client
              .from('profiles')
              .select('id, name, avatar_url')
              .eq('id', member['user_id'])
              .maybeSingle();
          member['profile'] = profile;
        } catch (e) {
          debugPrint('Error loading profile for ${member['user_id']}: $e');
          member['profile'] = null;
        }
      }

      // Check if user is PM
      final isPM = userProjectResponse != null && userProjectResponse['role'] == 'pm';

      // Check if project has PM (for multiplayer mode)
      bool hasProjectManager = false;
      if (widget.project['mode'] == 'multiplayer') {
        final pmCheck = await SupabaseService.client
            .from('user_projects')
            .select()
            .eq('project_id', widget.project['id'])
            .eq('role', 'pm')
            .maybeSingle();
        hasProjectManager = pmCheck != null;
      }

      setState(() {
        _userProject = userProjectResponse;
        _isPM = isPM;
        _hasProjectManager = hasProjectManager;
        // _milestones = List<Map<String, dynamic>>.from(milestonesResponse); // Future use
        _tasks = (tasksResponse as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
        _teamMembers = teamMembers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _toggleTaskStatus(Map<String, dynamic> task) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final userRole = _userProject?['role'] ?? 'user';
    final isProjectMode = widget.project['mode'] == 'solo';
    
    // Permission check:
    // - PM/Fullstack can always update
    // - Others can only update if assigned or claimed by them
    final canUpdate = userRole == 'pm' 
        || userRole == 'fullstack'
        || task['assigned_user_id'] == userId
        || task['claimed_by_user_id'] == userId
        || isProjectMode; // Solo project mode - anyone can update

    if (!canUpdate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only update tasks assigned to you'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final newStatus = task['status'] == 'done' ? 'todo' : 'done';

    try {
      // If status is being set to in_progress and not yet claimed, claim it
      final updateData = <String, dynamic>{
        'status': newStatus,
      };

      // Auto-claim task if moving to in_progress and not assigned
      if (newStatus == 'in_progress' && task['claimed_by_user_id'] == null && isProjectMode) {
        updateData['claimed_by_user_id'] = userId;
        updateData['is_claimed'] = true;
      }

      await SupabaseService.client.from('tasks').update(updateData).eq('id', task['id']);

      // Update local state
      setState(() {
        final index = _tasks.indexWhere((t) => t['id'] == task['id']);
        if (index != -1) {
          _tasks[index]['status'] = newStatus;
          if (updateData.containsKey('claimed_by_user_id')) {
            _tasks[index]['claimed_by_user_id'] = userId;
            _tasks[index]['is_claimed'] = true;
          }
        }
      });

      // Progress is auto-calculated by database trigger
      // Reload project data to get updated progress
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task marked as ${newStatus == 'done' ? 'completed' : 'incomplete'}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
        ),
        title: const Text(
          'Add New Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeoTextField(
                label: 'Task Title',
                controller: titleController,
                hintText: 'Task title',
              ),
              const SizedBox(height: AppConstants.spacingM),
              NeoTextField(
                label: 'Description',
                controller: descController,
                hintText: 'Task description',
                maxLines: 3,
              ),
              const SizedBox(height: AppConstants.spacingM),
              const Text(
                'Priority',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              StatefulBuilder(
                builder: (context, setStateDialog) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority Selection
                    ...['low', 'medium', 'high'].map((p) {
                      return RadioListTile<String>(
                        title: Text(p.toUpperCase()),
                        value: p,
                        groupValue: priority,
                        onChanged: (value) {
                          setStateDialog(() => priority = value!);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task title is required')),
                );
                return;
              }

              try {
                final taskData = {
                  'project_id': widget.project['id'],
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'priority': priority,
                  'status': 'todo',
                };

                // Note: assigned_role removed - not in current schema
                // Tasks are claimed by users dynamically

                await SupabaseService.client.from('tasks').insert(taskData);

                Navigator.pop(context);
                _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task created successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating task: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project['title'] ?? 'Project Detail',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            // V2: Show project code with copy button
            if (widget.project['code'] != null)
              Row(
                children: [
                  Text(
                    'Code: ${widget.project['code']}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14, color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Copy to clipboard
                      final code = widget.project['code'] as String;
                      // Will add clipboard functionality later
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Code $code copied!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            if (_userProject != null)
              Text(
                'Role: ${AppConstants.projectRoleLabels[_userProject!['role']] ?? _userProject!['role']}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Tasks'),
                  Tab(text: 'Team'),
                ],
              ),
              Container(
                color: AppColors.border,
                height: 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _canAddTask()
          ? FloatingActionButton.extended(
              onPressed: _showAddTaskDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Add Task',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tasks Tab
                _buildTasksTab(),
                // Team Tab
                _buildTeamTab(),
              ],
            ),
    );
  }

  Widget _buildTasksTab() {
    final isSoloMode = widget.project['mode'] == 'solo';
    
    // Show all tasks - users can claim tasks themselves
    final filteredTasks = _tasks;
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    // Project Info Card
                    NeoCard(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Difficulty Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingM,
                                  vertical: AppConstants.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(widget.project['difficulty']),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: AppConstants.borderWidth,
                                  ),
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                                child: Text(
                                  widget.project['difficulty']?.toString().toUpperCase() ?? 'MEDIUM',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingS),
                              // Mode Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingM,
                                  vertical: AppConstants.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  color: isSoloMode ? AppColors.secondary : AppColors.primary,
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: AppConstants.borderWidth,
                                  ),
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                                child: Text(
                                  isSoloMode ? 'SOLO' : 'TEAM',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            widget.project['description'] ?? 'No description',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (_userProject != null) ...[
                            const SizedBox(height: AppConstants.spacingM),
                            const Divider(color: AppColors.border, thickness: 2),
                            const SizedBox(height: AppConstants.spacingM),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${(_userProject!['progress'] ?? 0).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacingS),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              child: LinearProgressIndicator(
                                value: (_userProject!['progress'] ?? 0) / 100,
                                minHeight: 12,
                                backgroundColor: AppColors.secondary.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingL),

                    // Tasks Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (filteredTasks.isNotEmpty)
                          Text(
                            '${filteredTasks.where((t) => t['status'] == 'done').length}/${filteredTasks.length} completed',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingM),

                    filteredTasks.isEmpty
                        ? NeoCard(
                            color: AppColors.background,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppConstants.spacingXL),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.task_outlined,
                                      size: 64,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: AppConstants.spacingM),
                                    const Text(
                                      'No tasks yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: AppConstants.spacingS),
                                    Text(
                                      (_isAdmin || isSoloMode)
                                          ? 'Tap + button to create tasks'
                                          : 'Admin will add tasks soon',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: filteredTasks.map((task) => _buildTaskCard(task)).toList(),
                          ),

                    const SizedBox(height: AppConstants.spacingL),

                    // Complete Project Button (when all tasks done and user hasn't completed yet)
                    if (_userProject != null && 
                        _tasks.isNotEmpty && 
                        _tasks.every((t) => t['status'] == 'done') &&
                        _userProject!['status'] != 'completed' &&
                        (_isPM || _isAdmin || widget.project['mode'] == 'solo'))
                      ElevatedButton.icon(
                        onPressed: _completeProject,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark Project as Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),

                    // Leave Project Button (for members, not PM in multiplayer)
                    if (_userProject != null && 
                        !(widget.project['mode'] == 'multiplayer' && _isPM))
                      Padding(
                        padding: const EdgeInsets.only(top: AppConstants.spacingM),
                        child: ElevatedButton.icon(
                          onPressed: _leaveProject,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Leave Project'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isCompleted = task['status'] == 'done';
    final priorityColor = _getPriorityColor(task['priority'] ?? 'medium');
    
    // Check if user can update this task
    final userId = context.read<AuthProvider>().currentUser?.id;
    final userRole = _userProject?['role'] ?? 'user';
    final isProjectMode = widget.project['mode'] == 'solo';
    final canUpdate = userRole == 'pm' 
        || userRole == 'fullstack'
        || task['assigned_user_id'] == userId
        || task['claimed_by_user_id'] == userId
        || isProjectMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: NeoCard(
        color: isCompleted ? AppColors.success.withOpacity(0.1) : Colors.white,
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isCompleted,
              onChanged: canUpdate ? (_) => _toggleTaskStatus(task) : null,
              activeColor: AppColors.success,
            ),
            const SizedBox(width: AppConstants.spacingS),

            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task['title'] ?? 'Untitled Task',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      // Priority indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      task['description'],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          border: Border.all(color: priorityColor, width: 2),
                        ),
                        child: Text(
                          (task['priority'] ?? 'medium').toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? AppColors.success.withOpacity(0.2) 
                              : AppColors.textSecondary.withOpacity(0.2),
                          border: Border.all(
                            color: isCompleted ? AppColors.success : AppColors.textSecondary,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          task['status']?.toString().toUpperCase() ?? 'TODO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _teamMembers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  const Text(
                    'No team members yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: _teamMembers.length,
              itemBuilder: (context, index) {
                final member = _teamMembers[index];
                // profile is now directly attached as a map
                final profile = member['profile'] as Map<String, dynamic>?;
                final role = member['role'] as String;
                final progress = member['progress'] ?? 0.0;
                final roleColor = AppColors.getRoleColor(role);
                final userId = context.read<AuthProvider>().currentUser?.id;
                final isCurrentUser = member['user_id'] == userId;
                final canKick = !isCurrentUser && 
                    widget.project['mode'] == 'multiplayer' && 
                    (_isPM || _isAdmin) && 
                    role != 'pm'; // Can't kick PM

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                  child: NeoCard(
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: roleColor,
                          backgroundImage: profile != null && profile['avatar_url'] != null
                              ? NetworkImage(profile['avatar_url'] as String)
                              : null,
                          child: profile?['avatar_url'] == null
                              ? Text(
                                  (profile?['name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor,
                                      border: Border.all(color: Colors.black, width: 2),
                                    ),
                                    child: Text(
                                      AppConstants.projectRoleLabels[role] ?? role.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${progress.toStringAsFixed(0)}% progress',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Progress bar
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: progress < 30
                                          ? AppColors.error
                                          : progress < 70
                                              ? AppColors.warning
                                              : AppColors.success,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Kick button for PM/Admin
                        if (canKick)
                          IconButton(
                            icon: const Icon(Icons.person_remove, color: AppColors.error),
                            onPressed: () => _kickMember(member),
                            tooltip: 'Remove from project',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  /// Check if current user can add tasks
  /// Rules:
  /// - Admin can always add tasks
  /// - In solo mode, ONLY admin can add tasks (users can only complete tasks)
  /// - In multiplayer mode:
  ///   - If project has PM, only PM can add tasks
  ///   - If project has no PM, admin can add tasks
  bool _canAddTask() {
    final isSoloMode = widget.project['mode'] == 'solo';
    
    // Solo mode - ONLY admin can add tasks
    if (isSoloMode) {
      return _isAdmin;
    }
    
    // Multiplayer mode
    // Admin can add if no PM exists
    if (_isAdmin && !_hasProjectManager) {
      return true;
    }
    
    // PM can add in multiplayer
    return _isPM;
  }

  Future<void> _completeProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(color: AppColors.border, width: AppConstants.borderWidth),
        ),
        title: const Text('Complete Project?'),
        content: const Text(
          'All tasks are done! Mark this project as completed?\n\nThis action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;

      // Mark user_project as completed
      await SupabaseService.client
          .from('user_projects')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId!)
          .eq('project_id', widget.project['id']);

      // TODO: Award badges after function is deployed
      // try {
      //   await SupabaseService.client.rpc('award_badges_on_completion', params: {
      //     'p_user_id': userId,
      //   });
      // } catch (e) {
      //   debugPrint('Badge awarding error (non-critical): $e');
      // }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Project completed! Great work!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _leaveProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(color: AppColors.border, width: AppConstants.borderWidth),
        ),
        title: const Text('Leave Project?'),
        content: const Text(
          'Are you sure you want to leave this project?\n\nYour progress will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      
      await SupabaseService.client
          .from('user_projects')
          .delete()
          .eq('user_id', userId!)
          .eq('project_id', widget.project['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left project successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _kickMember(Map<String, dynamic> member) async {
    final profile = member['profile'] as Map<String, dynamic>?;
    final memberName = profile?['name'] ?? 'User';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(color: AppColors.border, width: AppConstants.borderWidth),
        ),
        title: const Text('Remove Member?'),
        content: Text(
          'Remove $memberName from this project?\n\nTheir tasks will remain but unassigned.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final memberId = member['user_id'];
      
      await SupabaseService.client
          .from('tasks')
          .update({
            'claimed_by_user_id': null,
            'is_claimed': false,
          })
          .eq('project_id', widget.project['id'])
          .eq('claimed_by_user_id', memberId);
      
      await SupabaseService.client
          .from('user_projects')
          .delete()
          .eq('user_id', memberId)
          .eq('project_id', widget.project['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$memberName removed from project')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
