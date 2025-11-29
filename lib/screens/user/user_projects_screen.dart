import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_card.dart';
import 'join_project_screen.dart';
import '../project/project_detail_screen.dart';

class UserProjectsScreen extends StatelessWidget {
  const UserProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    
    final userProjects = projectProvider.getProjectsByUserId(userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Projects',
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
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: NeoButton(
                text: 'Join Project',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JoinProjectScreen(),
                    ),
                  );
                },
                color: AppColors.accent,
                icon: Icons.add,
              ),
            ),
            Expanded(
              child: userProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppConstants.spacingL),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              border: Border.all(color: Colors.black, width: 3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.folder_open,
                              size: 80,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingL),
                          const Text(
                            'No projects yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          const Text(
                            'Join a project to get started!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL,
                      ),
                      itemCount: userProjects.length,
                      itemBuilder: (context, index) {
                        final project = userProjects[index];
                        final role = projectProvider.getUserRoleInProject(
                          project.id,
                          userId,
                        );
                        final stats = projectProvider.getProjectStats(project.id);
                        
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingL,
                          ),
                          child: NeoCard(
                            color: Colors.white,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProjectDetailScreen(
                                    projectId: project.id,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingS),
                                // Role Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingM,
                                    vertical: AppConstants.spacingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role ?? ''),
                                    border: Border.all(color: Colors.black, width: 2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    role ?? 'Member',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingM),
                                // Progress
                                Row(
                                  children: [
                                    const Icon(Icons.task, size: 16),
                                    const SizedBox(width: AppConstants.spacingS),
                                    Text(
                                      '${stats['completedTasks']} / ${stats['totalTasks']} tasks',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
}
