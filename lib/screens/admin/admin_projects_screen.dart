import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_card.dart';
import 'add_project_screen.dart';
import '../project/project_detail_screen.dart';

class AdminProjectsScreen extends StatelessWidget {
  const AdminProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final authProvider = context.watch<AuthProvider>();
    final adminId = authProvider.currentUser?.id ?? '';
    
    final adminProjects = projectProvider.projects
        .where((p) => p.adminId == adminId)
        .toList();

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
                text: 'Create New Project',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddProjectScreen(),
                    ),
                  );
                },
                color: AppColors.accent,
                icon: Icons.add,
              ),
            ),
            Expanded(
              child: adminProjects.isEmpty
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
                            'Create your first project!',
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
                      itemCount: adminProjects.length,
                      itemBuilder: (context, index) {
                        final project = adminProjects[index];
                        final stats = projectProvider.getProjectStats(project.id);
                        final members = projectProvider.getProjectMembers(project.id);
                        
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
                                // Project Name
                                Text(
                                  project.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingS),
                                // Project Code
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingM,
                                    vertical: AppConstants.spacingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'CODE: ${project.code}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingM),
                                // Stats
                                Row(
                                  children: [
                                    _buildStat(
                                      Icons.people,
                                      '${members.length} Members',
                                      AppColors.secondary,
                                    ),
                                    const SizedBox(width: AppConstants.spacingM),
                                    _buildStat(
                                      Icons.task,
                                      '${stats['totalTasks']} Tasks',
                                      AppColors.accent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.spacingM),
                                // Deadline
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: AppConstants.spacingS),
                                    Text(
                                      'Due: ${DateFormat('MMM d, y').format(project.deadline)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
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

  Widget _buildStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
