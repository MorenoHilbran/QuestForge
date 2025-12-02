import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../data/models/project_model.dart';
import '../../widgets/common/neo_card.dart';
import '../projects/join_project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectModel> _projects = [];
  Map<String, bool> _userJoinedProjects = {}; // projectId -> isJoined
  bool _isLoading = true;
  String _selectedDifficulty = 'all';

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
      final userId = context.read<AuthProvider>().currentUser?.id;
      
      // Load projects with joined users info, status, and role data for validation
      final response = _selectedDifficulty == 'all'
          ? await SupabaseService.client
              .from('projects')
              .select('*, user_projects(user_id, status, role, profiles(id, name, avatar_url))')
              .order('created_at', ascending: false)
          : await SupabaseService.client
              .from('projects')
              .select('*, user_projects(user_id, status, role, profiles(id, name, avatar_url))')
              .eq('difficulty', _selectedDifficulty)
              .order('created_at', ascending: false);
      
      final projectsData = (response as List).cast<Map<String, dynamic>>();
      
      // Process each project to add completion status
      final projects = <ProjectModel>[];
      for (var data in projectsData) {
        // Check if any user has completed this project
        final userProjects = data['user_projects'] as List?;
        bool isCompleted = false;
        if (userProjects != null) {
          isCompleted = userProjects.any((up) => up['status'] == 'completed');
        }
        data['isCompleted'] = isCompleted;
        
        projects.add(ProjectModel.fromJson(data));
      }
      
      // Check which projects user has joined
      final joinedMap = <String, bool>{};
      if (userId != null) {
        for (var project in projects) {
          if (project.joinedUsers != null) {
            joinedMap[project.id] = project.joinedUsers!.any((user) => user['id'] == userId);
          } else {
            joinedMap[project.id] = false;
          }
        }
      }
      
      setState(() {
        _projects = projects;
        _userJoinedProjects = joinedMap;
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

  int _getMaxMembers(ProjectModel project) {
    // Solo mode = 1 user
    if (project.mode == 'solo') return 1;
    
    // Multiplayer: count required roles or default to 6
    if (project.requiredRoles != null && project.requiredRoles!.isNotEmpty) {
      return project.requiredRoles!.length;
    }
    
    return 6; // Default max for multiplayer
  }

  Widget _buildJoinButton(ProjectModel project) {
    final isJoined = _userJoinedProjects[project.id] == true;
    final isFull = (project.joinedUsers?.length ?? 0) >= _getMaxMembers(project);
    final isCompleted = project.isCompleted;

    // Already joined
    if (isJoined) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.success,
          border: Border.all(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.border,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Already Joined',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Completed or Full - show disabled button
    if (isCompleted || isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withOpacity(0.3),
          border: Border.all(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.lock : Icons.people,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isCompleted ? 'Project Completed' : 'Project Full',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Available to join
    return GestureDetector(
      onTap: () async {
        // Fetch complete project data including role_limits
        final completeProject = await SupabaseService.client
            .from('projects')
            .select('*, user_projects(user_id, role)')
            .eq('id', project.id)
            .single();
        
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JoinProjectScreen(
              project: completeProject,
            ),
          ),
        );

        if (result == true && mounted) {
          _loadProjects(); // Refresh to show joined status
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project joined successfully!')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.border,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Join Project',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
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
              'QuestForge',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            Text(
              'Hi, ${user?.name ?? "User"}!',
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
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: AppConstants.spacingS),
                  _buildFilterChip('Easy', 'easy'),
                  const SizedBox(width: AppConstants.spacingS),
                  _buildFilterChip('Medium', 'medium'),
                  const SizedBox(width: AppConstants.spacingS),
                  _buildFilterChip('Hard', 'hard'),
                ],
              ),
            ),
          ),

          // Projects list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                    ? const Center(
                        child: Text(
                          'No projects available yet',
                          style: TextStyle(color: AppColors.textSecondary),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedDifficulty == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = value;
          _isLoading = true;
        });
        _loadProjects();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(4, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    Color difficultyColor;
    switch (project.difficulty) {
      case 'easy':
        difficultyColor = AppColors.success;
        break;
      case 'hard':
        difficultyColor = AppColors.error;
        break;
      default:
        difficultyColor = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: NeoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Thumbnail
              if (project.thumbnailUrl != null && project.thumbnailUrl!.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Image.network(
                    project.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (project.thumbnailUrl != null && project.thumbnailUrl!.isNotEmpty)
                const SizedBox(height: AppConstants.spacingM),

              // Title and Joined Users
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Show joined users avatars (multiplayer only)
                  if (project.mode == 'multiplayer' && 
                      project.joinedUsers != null && 
                      project.joinedUsers!.isNotEmpty) ...[
                    const SizedBox(width: AppConstants.spacingS),
                    Row(
                      children: [
                        // Show up to 3 avatars
                        ...project.joinedUsers!.take(3).map((user) {
                          return Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              backgroundImage: user['avatar_url'] != null
                                  ? NetworkImage(user['avatar_url'])
                                  : null,
                              child: user['avatar_url'] == null
                                  ? Text(
                                      (user['name'] ?? 'U')[0].toUpperCase(),
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
                        if (project.joinedUsers!.length > 3)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.textSecondary,
                              child: Text(
                                '+${project.joinedUsers!.length - 3}',
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
              const SizedBox(height: AppConstants.spacingS),

              // Description
              Text(
                project.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Badges Row: Difficulty and Completed
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                      vertical: AppConstants.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor,
                      border: Border.all(
                        color: AppColors.border,
                        width: AppConstants.borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Text(
                      project.difficulty.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (project.isCompleted) ...[
                    const SizedBox(width: AppConstants.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        border: Border.all(
                          color: AppColors.border,
                          width: AppConstants.borderWidth,
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingM),

              // User count and Join Status/Button
              Row(
                children: [
                  // User count (multiplayer only)
                  if (project.mode == 'multiplayer') ...[
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
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            '${project.joinedUsers?.length ?? 0}/${_getMaxMembers(project)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                  ],
                  
                  // Join Button or Joined Status
                  Expanded(
                    child: _buildJoinButton(project),
                  ),
                ],
              ),
            ],
        ),
      ),
    );
  }
}
