import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../data/models/project_user_model.dart';
import '../../widgets/common/neo_card.dart';
import '../../widgets/common/neo_progress_bar.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Map<String, dynamic>> _userProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
  }

  Future<void> _loadUserProjects() async {
    if (!SupabaseService.available) {
      setState(() => _isLoading = false);
      return;
    }

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('user_projects')
          .select('*, projects(*)')
          .eq('user_id', userId)
          .order('joined_at', ascending: false);

      final projects = (response as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // Calculate progress for each project
      for (var project in projects) {
        final projectId = project['project_id'];

        // Get all tasks for this project
        final tasksResponse = await SupabaseService.client
            .from('tasks')
            .select('status')
            .eq('project_id', projectId);

        final tasks = (tasksResponse as List);

        if (tasks.isNotEmpty) {
          final completedTasks = tasks
              .where((task) => task['status'] == 'done')
              .length;
          final totalTasks = tasks.length;
          project['progress'] = (completedTasks / totalTasks * 100).toDouble();
        } else {
          project['progress'] = 0.0;
        }
      }

      setState(() {
        _userProjects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading projects: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isAdmin ? 'Manage Projects' : 'My Projects',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 3),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_open,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    isAdmin
                        ? 'No projects created yet'
                        : 'No projects joined yet',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    isAdmin
                        ? 'Create your first project'
                        : 'Browse and join projects from Home',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserProjects,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                itemCount: _userProjects.length,
                itemBuilder: (context, index) {
                  return _buildProjectCard(_userProjects[index]);
                },
              ),
            ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> data) {
    final userProject = ProjectUserModel.fromJson(data);
    final project = data['projects'];

    Color statusColor;
    switch (userProject.status) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'abandoned':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: NeoCard(
        child: InkWell(
          onTap: () async {
            // Navigate to detail screen and wait for result
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(
                  project: {
                    'id': project['id'],
                    'title': project['title'],
                    'description': project['description'],
                    'difficulty': project['difficulty'],
                    'mode': project['mode'] ?? 'solo',
                    'required_roles': project['required_roles'],
                  },
                ),
              ),
            );

            // Reload projects when coming back to refresh progress
            if (mounted) {
              _loadUserProjects();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project title
              Text(
                project['title'] ?? 'Untitled Project',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),

              // Role & Mode badges
              Row(
                children: [
                  // For solo projects, only show one badge
                  // For multiplayer, show both role and mode
                  if ((project['mode'] ?? 'solo') == 'solo') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        border: Border.all(
                          color: AppColors.border,
                          width: AppConstants.borderWidth,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: const Text(
                        'SOLO',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Multiplayer: show role
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        border: Border.all(
                          color: AppColors.border,
                          width: AppConstants.borderWidth,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: Text(
                        AppConstants.projectRoleLabels[userProject.role] ??
                            userProject.role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    // Multiplayer: show mode
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(
                          color: AppColors.border,
                          width: AppConstants.borderWidth,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: const Text(
                        'MULTIPLAYER',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: NeoProgressBar(
                      progress: (data['progress'] ?? 0.0) / 100,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    '${(data['progress'] ?? 0.0).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  border: Border.all(
                    color: AppColors.border,
                    width: AppConstants.borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Text(
                  userProject.status.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
