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

  const ProjectDetailScreen({super.key, required this.project});

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
      final isAdmin =
          context.read<AuthProvider>().currentUser?.isAdmin ?? false;

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
      final teamMembers =
          (teamResponse as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
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
      final isPM =
          userProjectResponse != null && userProjectResponse['role'] == 'pm';

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
        _tasks =
            (tasksResponse as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _teamMembers = teamMembers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _toggleTaskStatus(Map<String, dynamic> task) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final userRole = _userProject?['role'] ?? 'user';
    final isSoloMode = widget.project['mode'] == 'solo';
    final assignedRole = task['assigned_role'] as String?;

    // Permission check:
    // - Admin can always update
    // - Solo mode: if joined (_userProject != null), can update any task
    // - PM can always update (including general tasks)
    // - Multiplayer:
    //   - General tasks (assigned_role = null) ONLY PM can update
    //   - Role-specific tasks: only matching role can update
    // - Or task already assigned/claimed to user
    final isGeneralTask = assignedRole == null;
    final isPMRole = _isPM || userRole == 'pm' || userRole == 'project_manager';
    final roleMatches = !isGeneralTask && assignedRole == userRole;
    final isJoinedSolo =
        isSoloMode && _userProject != null; // Solo: just need to be joined

    final canUpdate =
        _isAdmin ||
        isJoinedSolo || // Solo: if joined, can update any task
        isPMRole ||
        task['assigned_user_id'] == userId ||
        task['claimed_by_user_id'] == userId ||
        roleMatches; // Multiplayer: role matches (not general task)

    if (!canUpdate) {
      if (mounted) {
        final message = isSoloMode
            ? 'Please join this project first to update tasks'
            : isGeneralTask
            ? 'General tasks can only be updated by Project Manager'
            : 'This task is assigned to ${assignedRole ?? "another role"}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final newStatus = task['status'] == 'done' ? 'todo' : 'done';

    try {
      // If status is being set to in_progress and not yet claimed, claim it
      final updateData = <String, dynamic>{'status': newStatus};

      // Auto-claim task if moving to in_progress and not assigned
      if (newStatus == 'in_progress' &&
          task['claimed_by_user_id'] == null &&
          isSoloMode) {
        updateData['claimed_by_user_id'] = userId;
        updateData['is_claimed'] = true;
      }

      // Update database first - if RLS denies, this will throw error
      final response = await SupabaseService.client
          .from('tasks')
          .update(updateData)
          .eq('id', task['id'])
          .select();

      // Only update local state if database update successful
      if (response.isNotEmpty) {
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
              content: Text(
                'Task marked as ${newStatus == 'done' ? 'completed' : 'incomplete'}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().contains('policy') ? 'You don\'t have permission to update this task' : 'Failed to update task'}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _canCompleteProject() {
    // Check if project is already completed
    if (widget.project['status'] == 'completed') {
      return false;
    }

    // Check if all tasks are done
    if (_tasks.isEmpty) {
      return false;
    }

    final allTasksDone = _tasks.every((task) => task['status'] == 'done');
    return allTasksDone;
  }

  Future<void> _completeProject() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
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
          'Complete Project',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to mark this project as completed?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.success,
                  width: AppConstants.borderWidth,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      SizedBox(width: AppConstants.spacingS),
                      Text(
                        'This will:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  const Text(
                    '• Mark project as completed',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const Text(
                    '• Award badges to all team members',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const Text(
                    '• Update team member achievements',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Team members: ${_teamMembers.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Complete Project'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;

      // Call complete_project function
      final response = await SupabaseService.client.rpc(
        'complete_project',
        params: {'p_project_id': widget.project['id'], 'p_user_id': userId},
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Project completed!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Reload data to show updated status
        await _loadData();

        // Navigate back to projects list after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Failed to complete project',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing project: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';
    String? assignedRole;
    final isMultiplayer = widget.project['mode'] == 'multiplayer';

    // Get required roles from project (defined by admin when creating project)
    // This allows PM to create tasks for roles even before anyone joins with that role
    List<String> availableRoles = [];
    if (isMultiplayer && widget.project['required_roles'] != null) {
      final requiredRoles = widget.project['required_roles'];
      if (requiredRoles is List) {
        availableRoles = requiredRoles
            .map((r) => r.toString())
            .where((r) => r != 'pm' && r != 'project_manager')
            .toList();
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
        ),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Flexible(
                child: SingleChildScrollView(
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

                            // Role Assignment (only for multiplayer)
                            if (isMultiplayer && availableRoles.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacingM),
                              const Divider(),
                              const SizedBox(height: AppConstants.spacingM),
                              const Text(
                                'Assign to Role',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingS),
                              DropdownButtonFormField<String>(
                                value: assignedRole,
                                decoration: InputDecoration(
                                  hintText: 'Select role (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius,
                                    ),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Any role'),
                                  ),
                                  ...availableRoles.map(
                                    (role) => DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(
                                        AppConstants.projectRoleLabels[role!] ??
                                            role,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setStateDialog(() => assignedRole = value);
                                },
                              ),
                              const SizedBox(height: AppConstants.spacingS),
                              const Text(
                                'Users with this role can claim this task',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task title is required'),
                          ),
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
                          'assigned_role': assignedRole,
                        };

                        await SupabaseService.client
                            .from('tasks')
                            .insert(taskData);

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
            ],
          ),
        ),
      ),
    );
  }

  void _editTask(Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descController = TextEditingController(
      text: task['description'] ?? '',
    );
    String priority = task['priority'] ?? 'medium';
    String? assignedRole = task['assigned_role'];
    final isMultiplayer = widget.project['mode'] == 'multiplayer';

    // Get required roles from project
    List<String> availableRoles = [];
    if (isMultiplayer && widget.project['required_roles'] != null) {
      final requiredRoles = widget.project['required_roles'];
      if (requiredRoles is List) {
        availableRoles = requiredRoles
            .map((r) => r.toString())
            .where((r) => r != 'pm' && r != 'project_manager')
            .toList();
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
        ),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Flexible(
                child: SingleChildScrollView(
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

                            // Role Assignment (only for multiplayer)
                            if (isMultiplayer && availableRoles.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacingM),
                              const Divider(),
                              const SizedBox(height: AppConstants.spacingM),
                              const Text(
                                'Assign to Role',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingS),
                              DropdownButtonFormField<String>(
                                value: assignedRole,
                                decoration: InputDecoration(
                                  hintText: 'Select role (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius,
                                    ),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Any role'),
                                  ),
                                  ...availableRoles.map(
                                    (role) => DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(
                                        AppConstants.projectRoleLabels[role!] ??
                                            role,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setStateDialog(() => assignedRole = value);
                                },
                              ),
                              const SizedBox(height: AppConstants.spacingS),
                              const Text(
                                'Users with this role can claim this task',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task title is required'),
                          ),
                        );
                        return;
                      }

                      try {
                        final updateData = {
                          'title': titleController.text.trim(),
                          'description': descController.text.trim(),
                          'priority': priority,
                          'assigned_role': assignedRole,
                        };

                        await SupabaseService.client
                            .from('tasks')
                            .update(updateData)
                            .eq('id', task['id']);

                        Navigator.pop(context);
                        _loadData();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task updated successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating task: $e')),
                        );
                      }
                    },
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteTask(Map<String, dynamic> task) {
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
          'Delete Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this task?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.error,
                  width: AppConstants.borderWidth,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? 'Untitled Task',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (task['description'] != null &&
                      task['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      task['description'],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.client
                    .from('tasks')
                    .delete()
                    .eq('id', task['id']);

                Navigator.pop(context);
                _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task deleted successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting task: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
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
                    icon: const Icon(
                      Icons.copy,
                      size: 14,
                      color: AppColors.primary,
                    ),
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
              Container(color: AppColors.border, height: 3),
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
    final isMultiplayer = widget.project['mode'] == 'multiplayer';

    // For multiplayer, group tasks by role
    Map<String, List<Map<String, dynamic>>> tasksByRole = {};
    List<Map<String, dynamic>> unassignedTasks = [];

    if (isMultiplayer) {
      for (var task in _tasks) {
        final role = task['assigned_role'] as String?;
        if (role == null) {
          unassignedTasks.add(task);
        } else {
          if (!tasksByRole.containsKey(role)) {
            tasksByRole[role] = [];
          }
          tasksByRole[role]!.add(task);
        }
      }
    }

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
                          color: _getDifficultyColor(
                            widget.project['difficulty'],
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: AppConstants.borderWidth,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        child: Text(
                          widget.project['difficulty']
                                  ?.toString()
                                  .toUpperCase() ??
                              'MEDIUM',
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
                          color: isSoloMode
                              ? AppColors.secondary
                              : AppColors.primary,
                          border: Border.all(
                            color: AppColors.border,
                            width: AppConstants.borderWidth,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
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

                    // Multiplayer: Show both overall and role progress
                    if (isMultiplayer) ...[
                      // Overall Project Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Overall Project Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_calculateOverallProgress().toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        child: LinearProgressIndicator(
                          value: _calculateOverallProgress() / 100,
                          minHeight: 12,
                          backgroundColor: AppColors.secondary.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),

                      // User's Role Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Progress (${AppConstants.projectRoleLabels[_userProject!['role']] ?? _userProject!['role']})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_calculateRoleProgress(_userProject!['role']).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        child: LinearProgressIndicator(
                          value:
                              _calculateRoleProgress(_userProject!['role']) /
                              100,
                          minHeight: 12,
                          backgroundColor: AppColors.secondary.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.success,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Solo: Show user progress only
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
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        child: LinearProgressIndicator(
                          value: (_userProject!['progress'] ?? 0) / 100,
                          minHeight: 12,
                          backgroundColor: AppColors.secondary.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Complete Project Button (PM only, when all tasks done)
                  if (_isPM && _canCompleteProject()) ...[
                    const SizedBox(height: AppConstants.spacingL),
                    const Divider(color: AppColors.border, thickness: 2),
                    const SizedBox(height: AppConstants.spacingL),
                    ElevatedButton.icon(
                      onPressed: _completeProject,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        'Complete Project & Award Badges',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
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
                if (_tasks.isNotEmpty)
                  Text(
                    '${_tasks.where((t) => t['status'] == 'done').length}/${_tasks.length} completed',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),

            _tasks.isEmpty
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
                : isMultiplayer
                // Multiplayer: Show tasks grouped by role
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unassigned tasks (any role can claim)
                      if (unassignedTasks.isNotEmpty) ...[
                        const Text(
                          'General Tasks (Any Role)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        ...unassignedTasks
                            .map((task) => _buildTaskCard(task))
                            .toList(),
                        const SizedBox(height: AppConstants.spacingL),
                      ],

                      // Tasks grouped by role
                      ...tasksByRole.entries.map((entry) {
                        final role = entry.key;
                        final tasks = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingM,
                                    vertical: AppConstants.spacingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius,
                                    ),
                                  ),
                                  child: Text(
                                    AppConstants.projectRoleLabels[role] ??
                                        role.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingS),
                                Text(
                                  '${tasks.where((t) => t['status'] == 'done').length}/${tasks.length}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacingS),
                            ...tasks
                                .map((task) => _buildTaskCard(task))
                                .toList(),
                            const SizedBox(height: AppConstants.spacingL),
                          ],
                        );
                      }).toList(),
                    ],
                  )
                // Solo: Show all tasks in a list
                : Column(
                    children: _tasks
                        .map((task) => _buildTaskCard(task))
                        .toList(),
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
    final assignedRole = task['assigned_role'] as String?;

    // Check if user can update this task
    final userId = context.read<AuthProvider>().currentUser?.id;
    final userRole = _userProject?['role'] ?? 'user';
    final isSoloMode = widget.project['mode'] == 'solo';
    final isMultiplayer = widget.project['mode'] == 'multiplayer';

    // Permission check (MUST match _toggleTaskStatus logic):
    // - Admin can always update
    // - Solo mode: if joined (_userProject != null), can update any task
    // - PM can always update (including general tasks)
    // - Multiplayer:
    //   - General tasks (assigned_role = null) ONLY PM can update
    //   - Role-specific tasks: only matching role can update
    // - Or task already assigned/claimed to user
    final isGeneralTask = assignedRole == null;
    final isPMRole = _isPM || userRole == 'pm' || userRole == 'project_manager';
    final roleMatches = !isGeneralTask && assignedRole == userRole;
    final isJoinedSolo =
        isSoloMode && _userProject != null; // Solo: just need to be joined

    final canUpdate =
        _isAdmin ||
        isJoinedSolo || // Solo: if joined, can update any task
        isPMRole ||
        task['assigned_user_id'] == userId ||
        task['claimed_by_user_id'] == userId ||
        roleMatches;

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
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
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
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                      ),
                      // Edit/Delete menu (PM/Admin only)
                      if (_isPM || _isAdmin) ...[
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editTask(task);
                            } else if (value == 'delete') {
                              _deleteTask(task);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (task['description'] != null &&
                      task['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      task['description'],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          border: Border.all(color: priorityColor, width: 2),
                        ),
                        child: Text(
                          (task['priority'] ?? 'medium')
                              .toString()
                              .toUpperCase(),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.textSecondary.withOpacity(0.2),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.textSecondary,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          task['status']?.toString().toUpperCase() ?? 'TODO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      // Show role badge if not in role-grouped view
                      if (assignedRole != null && !isMultiplayer) ...[
                        const SizedBox(width: AppConstants.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            AppConstants.projectRoleLabels[assignedRole] ??
                                assignedRole.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      // Show lock icon if user can't claim (wrong role)
                      if (isMultiplayer &&
                          assignedRole != null &&
                          assignedRole != userRole &&
                          !_isAdmin &&
                          !_isPM) ...[
                        const SizedBox(width: AppConstants.spacingS),
                        const Icon(
                          Icons.lock,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
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
                final canKick =
                    !isCurrentUser &&
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
                          backgroundImage:
                              profile != null && profile['avatar_url'] != null
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
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      AppConstants.projectRoleLabels[role] ??
                                          role.toUpperCase(),
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
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
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
                            icon: const Icon(
                              Icons.person_remove,
                              color: AppColors.error,
                            ),
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

  Future<void> _leaveProject() async {
    final confirm = await showDialog<bool>(
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
        title: const Text('Leave Project?'),
        content: const Text(
          'Are you sure you want to leave this project?\n\nYour progress will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;

      // Check if user_project exists before delete
      final beforeDelete = await SupabaseService.client
          .from('user_projects')
          .select()
          .eq('user_id', userId!)
          .eq('project_id', widget.project['id'])
          .maybeSingle();

      if (beforeDelete == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are not a member of this project'),
            ),
          );
        }
        return;
      }

      // Perform delete
      final deleteResult = await SupabaseService.client
          .from('user_projects')
          .delete()
          .eq('user_id', userId)
          .eq('project_id', widget.project['id'])
          .select(); // Add select to get deleted rows

      // Verify deletion
      final afterDelete = await SupabaseService.client
          .from('user_projects')
          .select()
          .eq('user_id', userId)
          .eq('project_id', widget.project['id'])
          .maybeSingle();

      if (mounted) {
        if (afterDelete == null) {
          // Successfully deleted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Left project successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Pop back to previous screen with refresh signal
          Navigator.pop(context, true);
        } else {
          // Delete failed - still exists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to leave project. Deleted: ${deleteResult?.length ?? 0} rows',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving project: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
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
          side: const BorderSide(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
        ),
        title: const Text('Remove Member?'),
        content: Text(
          'Remove $memberName from this project?\n\nTheir tasks will remain but unassigned.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
          .update({'claimed_by_user_id': null, 'is_claimed': false})
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Calculate overall project progress (all tasks)
  double _calculateOverallProgress() {
    if (_tasks.isEmpty) return 0.0;
    final completedTasks = _tasks.where((t) => t['status'] == 'done').length;
    return (completedTasks / _tasks.length) * 100;
  }

  // Calculate progress for specific role (tasks assigned to that role, NOT general tasks)
  double _calculateRoleProgress(String? userRole) {
    if (_tasks.isEmpty || userRole == null) return 0.0;

    // PM counts all tasks (including general tasks)
    // Other roles count ONLY tasks assigned to their role (NOT general tasks)
    final isPMRole = userRole == 'pm' || userRole == 'project_manager';
    final roleTasks = isPMRole
        ? _tasks
        : _tasks.where((t) {
            final assignedRole = t['assigned_role'] as String?;
            return assignedRole == userRole; // NOT NULL, must match exactly
          }).toList();

    if (roleTasks.isEmpty) return 0.0;

    final completedRoleTasks = roleTasks
        .where((t) => t['status'] == 'done')
        .length;
    return (completedRoleTasks / roleTasks.length) * 100;
  }
}
