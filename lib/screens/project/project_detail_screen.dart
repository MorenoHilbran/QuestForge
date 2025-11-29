import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/neo_card.dart';
import '../../widgets/common/neo_progress_bar.dart';
import '../../widgets/common/neo_button.dart';
import 'tasks_screen.dart';
import 'milestones_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final project = projectProvider.getProjectById(projectId);
    final members = projectProvider.getProjectMembers(projectId);
    final stats = projectProvider.getProjectStats(projectId);
    final userRole = projectProvider.getUserRoleInProject(
      projectId,
      authProvider.currentUser?.id ?? '',
    );
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    if (project == null) {
      return Scaffold(
        body: const Center(child: Text('Project not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          project.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Code Card
              NeoCard(
                color: AppColors.primary,
                child: Column(
                  children: [
                    const Text(
                      'PROJECT CODE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      project.code,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Progress Card
              NeoCard(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    NeoProgressBar(
                      progress: stats['progress'].toDouble(),
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Text(
                      '${stats['completedTasks']} of ${stats['totalTasks']} tasks completed',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: NeoCard(
                      color: AppColors.secondary,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 32,
                            color: Colors.black,
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            '${members.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Members',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: NeoCard(
                      color: AppColors.accent,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.flag,
                            size: 32,
                            color: Colors.black,
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            '${stats['totalMilestones']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Milestones',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Deadline Card
              NeoCard(
                color: Colors.white,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, y').format(project.deadline),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Your Role (if not admin)
              if (!isAdmin && userRole != null)
                NeoCard(
                  color: _getRoleColor(userRole),
                  child: Row(
                    children: [
                      Icon(
                        _getRoleIcon(userRole),
                        size: 32,
                        color: Colors.black,
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Role',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userRole,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppConstants.spacingL),
              // Action Buttons
              NeoButton(
                text: 'View Tasks',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TasksScreen(projectId: projectId),
                    ),
                  );
                },
                color: AppColors.primary,
                icon: Icons.task,
              ),
              const SizedBox(height: AppConstants.spacingM),
              NeoButton(
                text: 'View Milestones',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MilestonesScreen(projectId: projectId),
                    ),
                  );
                },
                color: AppColors.secondary,
                icon: Icons.flag,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Frontend':
        return AppColors.roleFrontend;
      case 'Backend':
        return AppColors.roleBackend;
      case 'Project Manager':
        return AppColors.rolePM;
      case 'UI/UX':
        return AppColors.roleUIUX;
      default:
        return AppColors.primary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Frontend':
        return Icons.web;
      case 'Backend':
        return Icons.storage;
      case 'Project Manager':
        return Icons.manage_accounts;
      case 'UI/UX':
        return Icons.palette;
      default:
        return Icons.person;
    }
  }
}
