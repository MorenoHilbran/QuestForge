import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/task_model.dart';
import '../../data/models/activity_log_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/neo_card.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_text_field.dart';

class TasksScreen extends StatefulWidget {
  final String projectId;

  const TasksScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;
    final userRole = projectProvider.getUserRoleInProject(
      widget.projectId,
      authProvider.currentUser?.id ?? '',
    );
    
    List<TaskModel> tasks;
    if (_selectedFilter != null) {
      tasks = projectProvider.getTasksByProjectAndRole(
        widget.projectId,
        _selectedFilter!,
      );
    } else if (isAdmin || userRole == 'Project Manager') {
      tasks = projectProvider.getTasksByProject(widget.projectId);
    } else {
      tasks = projectProvider.getTasksByProjectAndRole(
        widget.projectId,
        userRole ?? '',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Tasks',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            if (isAdmin || userRole == 'Project Manager')
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    ...AppConstants.roles.map(
                      (role) => _buildFilterChip(role, role),
                    ),
                  ],
                ),
              ),
            // Add Task Button (PM only)
            if (isAdmin || userRole == 'Project Manager')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                ),
                child: NeoButton(
                  text: 'Add Task',
                  onPressed: () => _showAddTaskDialog(context),
                  color: AppColors.accent,
                  icon: Icons.add,
                ),
              ),
            const SizedBox(height: AppConstants.spacingM),
            // Tasks List
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL,
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingM,
                          ),
                          child: NeoCard(
                            color: _getStatusColor(task.status),
                            onTap: () => _showTaskDetail(context, task),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(task.priority),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        task.priority,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  task.assignedRole,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedRole = AppConstants.roles[0];
    String selectedPriority = AppConstants.taskPriority[1];
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeoTextField(
                  label: 'Title',
                  controller: titleController,
                ),
                const SizedBox(height: 16),
                NeoTextField(
                  label: 'Description',
                  controller: descController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: AppConstants.roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: AppConstants.taskPriority.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPriority = value!;
                    });
                  },
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
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final task = TaskModel(
                    id: const Uuid().v4(),
                    projectId: widget.projectId,
                    title: titleController.text,
                    assignedRole: selectedRole,
                    priority: selectedPriority,
                    deadline: selectedDeadline,
                    description: descController.text,
                  );
                  
                  context.read<ProjectProvider>().addTask(task);
                  
                  // Add activity log
                  final log = ActivityLogModel(
                    id: const Uuid().v4(),
                    projectId: widget.projectId,
                    message: 'Task "${task.title}" created',
                    userId: context.read<AuthProvider>().currentUser?.id ?? '',
                    userName: context.read<AuthProvider>().currentUser?.name ?? '',
                  );
                  context.read<ProjectProvider>().addActivityLog(log);
                  
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetail(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${task.assignedRole}'),
            Text('Priority: ${task.priority}'),
            Text('Status: ${task.status}'),
            if (task.description != null)
              Text('Description: ${task.description}'),
          ],
        ),
        actions: [
          ...AppConstants.taskStatus.map((status) {
            return TextButton(
              onPressed: () {
                context.read<ProjectProvider>().updateTask(
                  task.copyWith(status: status),
                );
                Navigator.pop(context);
              },
              child: Text(status),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To-do':
        return AppColors.statusTodo;
      case 'In Progress':
        return AppColors.statusInProgress;
      case 'Review':
        return AppColors.statusReview;
      case 'Done':
        return AppColors.statusDone;
      default:
        return Colors.white;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.priorityHigh;
      case 'Medium':
        return AppColors.priorityMedium;
      case 'Low':
        return AppColors.priorityLow;
      default:
        return Colors.grey;
    }
  }
}
