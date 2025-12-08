import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/neo_card.dart';
import '../projects/project_detail_screen.dart';

class AdminMonitoringScreen extends StatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!SupabaseService.available) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load all projects with user count
      final response = await SupabaseService.client
          .from('projects')
          .select('''
            *,
            user_projects(
              id,
              user_id,
              role,
              progress
            )
          ''')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final projects = (response as List).cast<Map<String, dynamic>>();
      
      // V2: Progress is auto-calculated by database triggers!
      // No need to manually calculate actualProgress anymore.

      setState(() {
        _projects = projects;
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

  double _calculateProjectProgress(Map<String, dynamic> project) {
    // V2: Get average progress from all user_projects
    final userProjects = project['user_projects'] as List?;
    if (userProjects == null || userProjects.isEmpty) return 0.0;
    
    double totalProgress = 0.0;
    for (var up in userProjects) {
      totalProgress += (up['progress'] as num?)?.toDouble() ?? 0.0;
    }
    return totalProgress / userProjects.length;
  }

  int _getUserCount(Map<String, dynamic> project) {
    final userProjects = project['user_projects'] as List?;
    return userProjects?.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Monitoring',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            Text(
              'Admin: ${user?.name ?? "Admin"}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
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
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      const Text(
                        'No projects yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(_projects[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final progress = _calculateProjectProgress(project);
    final userCount = _getUserCount(project);
    final userProjects = project['user_projects'] as List?;
    final difficulty = project['difficulty'] as String?;

    Color difficultyColor;
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        difficultyColor = AppColors.easy;
        break;
      case 'hard':
        difficultyColor = AppColors.hard;
        break;
      default:
        difficultyColor = AppColors.medium;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: NeoCard(
        onTap: () {
          // Navigate to project detail for monitoring
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: project),
            ),
          ).then((_) => _loadProjects());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and User Avatars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(
                              difficulty?.toUpperCase() ?? 'MEDIUM',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                                  ? AppColors.solo
                                  : AppColors.team,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(
                              project['mode'] == 'solo' ? 'SOLO' : 'TEAM',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Show joined users avatars
                if (userProjects != null && userProjects.isNotEmpty) ...[
                  const SizedBox(width: AppConstants.spacingS),
                  Row(
                    children: [
                      // Show up to 3 avatars
                      ...userProjects.take(3).map((up) {
                        final profile = up['profiles'];
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            backgroundImage: profile?['avatar_url'] != null
                                ? NetworkImage(profile['avatar_url'])
                                : null,
                            child: profile?['avatar_url'] == null
                                ? Text(
                                    (profile?['name'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                      // Show +N if more than 3 users
                      if (userProjects.length > 3)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.textSecondary,
                            child: Text(
                              '+${userProjects.length - 3}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Description
            Text(
              project['description'] ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Stats Row
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$userCount ${userCount == 1 ? 'user' : 'users'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.toStringAsFixed(0)}% complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingS),

            // Progress Bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (progress / 100).clamp(0.0, 1.0),
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

            const SizedBox(height: AppConstants.spacingS),

            // Tap to view details
            Text(
              'Tap to view details and tasks →',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
