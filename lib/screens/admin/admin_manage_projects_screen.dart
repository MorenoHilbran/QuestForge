import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/neo_card.dart';
import '../projects/project_detail_screen.dart';

class AdminManageProjectsScreen extends StatefulWidget {
  const AdminManageProjectsScreen({super.key});

  @override
  State<AdminManageProjectsScreen> createState() => _AdminManageProjectsScreenState();
}

class _AdminManageProjectsScreenState extends State<AdminManageProjectsScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await SupabaseService.client
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _projects = (response as List).map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e')),
        );
      }
    }
  }

  Future<void> _deleteProject(String projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.client
            .from('projects')
            .delete()
            .eq('id', projectId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully')),
          );
          _loadProjects();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting project: $e')),
          );
        }
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? project}) {
    final isEdit = project != null;
    final titleController = TextEditingController(text: project?['title'] ?? '');
    final descController = TextEditingController(text: project?['description'] ?? '');
    final thumbnailController = TextEditingController(text: project?['thumbnail_url'] ?? '');
    String difficulty = project?['difficulty'] ?? 'medium';
    String mode = project?['mode'] ?? 'solo';
    List<String> requiredRoles = project?['required_roles'] != null 
        ? List<String>.from(project!['required_roles']) 
        : [];
    
    // Role limits
    Map<String, int> roleLimits = {};
    if (project?['role_limits'] != null) {
      final limitsData = project!['role_limits'] as Map<String, dynamic>;
      limitsData.forEach((key, value) {
        if (value is int) {
          roleLimits[key] = value;
        }
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Project' : 'Add New Project'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Project Title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: thumbnailController,
                    decoration: const InputDecoration(
                      labelText: 'Thumbnail URL (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => difficulty = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: mode,
                    decoration: const InputDecoration(
                      labelText: 'Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'solo', child: Text('Solo')),
                      DropdownMenuItem(value: 'multiplayer', child: Text('Team/Multiplayer')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        mode = value!;
                        if (mode == 'solo') {
                          requiredRoles = [];
                        }
                      });
                    },
                  ),
                  if (mode == 'multiplayer') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Required Roles for Team:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppConstants.projectRoles.map((role) {
                        final isSelected = requiredRoles.contains(role);
                        return FilterChip(
                          label: Text(AppConstants.projectRoleLabels[role] ?? role),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                requiredRoles.add(role);
                              } else {
                                requiredRoles.remove(role);
                              }
                            });
                          },
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.black,
                        );
                      }).toList(),
                    ),
                    if (requiredRoles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '⚠️ Select at least one role for team projects',
                          style: TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    // Role limits section
                    if (requiredRoles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Role Limits (Optional):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...requiredRoles.map((role) {
                        final controller = TextEditingController(
                          text: roleLimits[role]?.toString() ?? '2',
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppConstants.projectRoleLabels[role] ?? role,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Max Users',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final intValue = int.tryParse(value);
                                    if (intValue != null && intValue > 0) {
                                      roleLimits[role] = intValue;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Text(
                        'Set maximum number of users for each role',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || descController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                if (mode == 'multiplayer' && requiredRoles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one role for team projects')),
                  );
                  return;
                }

                final auth = context.read<AuthProvider>();
                // Ensure role limits are set for all required roles
                if (mode == 'multiplayer') {
                  for (var role in requiredRoles) {
                    roleLimits.putIfAbsent(role, () => 2); // Default to 2 if not set
                  }
                }

                final data = {
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'thumbnail_url': thumbnailController.text.trim().isEmpty 
                      ? null 
                      : thumbnailController.text.trim(),
                  'difficulty': difficulty,
                  'mode': mode,
                  'required_roles': mode == 'multiplayer' ? requiredRoles : null,
                  'role_limits': mode == 'multiplayer' && roleLimits.isNotEmpty 
                      ? roleLimits 
                      : null,
                  'created_by_admin': auth.currentUser?.id,
                };

                try {
                  if (isEdit) {
                    await SupabaseService.client
                        .from('projects')
                        .update(data)
                        .eq('id', project['id']);
                  } else {
                    await SupabaseService.client
                        .from('projects')
                        .insert(data);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Project ${isEdit ? 'updated' : 'created'} successfully')),
                    );
                    _loadProjects();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
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
        title: const Text(
          'Manage Projects',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 3,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProjects,
              child: _projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 80,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No projects yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            'Tap + to create your first project',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                          child: NeoCard(
                            onTap: () {
                              // Navigate to project detail
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProjectDetailScreen(
                                    project: project,
                                  ),
                                ),
                              ).then((_) => _loadProjects());
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project['title'] ?? 'Untitled',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getDifficultyColor(project['difficulty']),
                                                  border: Border.all(color: Colors.black, width: 2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  project['difficulty']?.toUpperCase() ?? 'MEDIUM',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: project['mode'] == 'solo' 
                                                      ? AppColors.secondary 
                                                      : AppColors.primary,
                                                  border: Border.all(color: Colors.black, width: 2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  project['mode']?.toUpperCase() ?? 'SOLO',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showAddEditDialog(project: project),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.error),
                                      onPressed: () => _deleteProject(project['id']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.spacingM),
                                Text(
                                  project['description'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (project['mode'] == 'multiplayer' && 
                                    project['required_roles'] != null &&
                                    (project['required_roles'] as List).isNotEmpty) ...[
                                  const SizedBox(height: AppConstants.spacingS),
                                  Text(
                                    'Required Roles:',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: (project['required_roles'] as List).map((role) {
                                      final roleColor = AppColors.getRoleColor(role);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: roleColor,
                                          border: Border.all(color: Colors.black, width: 2),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          AppConstants.projectRoleLabels[role] ?? role,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                if (project['thumbnail_url'] != null) ...[
                                  const SizedBox(height: AppConstants.spacingS),
                                  Text(
                                    '🖼️ Has thumbnail',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Add Project',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  @override
  void dispose() {
    super.dispose();
  }
}
