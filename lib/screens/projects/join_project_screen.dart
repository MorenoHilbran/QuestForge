import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_card.dart';

class JoinProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const JoinProjectScreen({super.key, required this.project});

  @override
  State<JoinProjectScreen> createState() => _JoinProjectScreenState();
}

class _JoinProjectScreenState extends State<JoinProjectScreen> {
  String? _selectedRole;
  bool _isLoading = false;
  Map<String, int> _currentRoleCounts = {};
  Map<String, int> _roleLimits = {};

  @override
  void initState() {
    super.initState();
    _loadRoleAvailability();
  }

  Future<void> _loadRoleAvailability() async {
    if (widget.project['mode'] != 'multiplayer') return;

    try {
      // Load current role counts
      final response = await SupabaseService.client
          .from('user_projects')
          .select('role')
          .eq('project_id', widget.project['id']);

      final roleCounts = <String, int>{};
      for (var userProject in response as List) {
        final role = userProject['role'] as String;
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }

      // Load role limits from project
      final roleLimitsData = widget.project['role_limits'] as Map<String, dynamic>?;
      final limits = <String, int>{};
      if (roleLimitsData != null) {
        roleLimitsData.forEach((key, value) {
          if (value is int) {
            limits[key] = value;
          }
        });
      }

      if (mounted) {
        setState(() {
          _currentRoleCounts = roleCounts;
          _roleLimits = limits;
        });
      }
    } catch (e) {
      debugPrint('Error loading role availability: $e');
    }
  }

  bool _isRoleFull(String role) {
    if (_roleLimits.isEmpty) return false; // No limits set
    final limit = _roleLimits[role] ?? 999; // Default high limit
    final current = _currentRoleCounts[role] ?? 0;
    return current >= limit;
  }

  Future<void> _joinProject() async {
    final auth = context.read<AuthProvider>();
    
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final isSolo = widget.project['mode'] == 'solo';
    
    if (!isSolo && _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    // Check if role is full (for multiplayer)
    if (!isSolo && _selectedRole != null && _isRoleFull(_selectedRole!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role ${_selectedRole!.toUpperCase()} is full. Please choose another role.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Insert into user_projects
      await SupabaseService.client.from('user_projects').insert({
        'user_id': auth.currentUser!.id,
        'project_id': widget.project['id'],
        'role': _selectedRole ?? 'solo',
        'mode': widget.project['mode'] ?? 'solo',
        'progress': 0,
        'status': 'in_progress',
      });

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined ${widget.project['title']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSolo = widget.project['mode'] == 'solo';
    final requiredRoles = widget.project['required_roles'] as List?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join Project',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Project Info Card
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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
                          color: _getDifficultyColor(widget.project['difficulty']),
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.project['difficulty']?.toUpperCase() ?? 'MEDIUM',
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
                          color: isSolo ? AppColors.secondary : AppColors.primary,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isSolo ? 'SOLO' : 'TEAM',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    widget.project['description'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Role Selection (for team mode)
            if (!isSolo) ...[
              Text(
                'Select Your Role',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Choose the role you want to take in this project',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingM),

              if (requiredRoles != null && requiredRoles.isNotEmpty)
                ...requiredRoles.map((role) {
                  final isSelected = _selectedRole == role;
                  final isFull = _isRoleFull(role);
                  final currentCount = _currentRoleCounts[role] ?? 0;
                  final limit = _roleLimits[role] ?? 999;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: Opacity(
                      opacity: isFull ? 0.5 : 1.0,
                      child: InkWell(
                        onTap: isFull ? null : () {
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                        child: NeoCard(
                          color: isFull 
                              ? Colors.grey.shade300 
                              : (isSelected ? AppColors.primary : Colors.white),
                          child: Row(
                            children: [
                              Icon(
                                isFull 
                                    ? Icons.block 
                                    : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                                color: Colors.black,
                              ),
                              const SizedBox(width: AppConstants.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppConstants.projectRoleLabels[role] ?? role,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        // Show availability
                                        if (_roleLimits.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isFull ? AppColors.error : AppColors.success,
                                              border: Border.all(color: Colors.black, width: 2),
                                            ),
                                            child: Text(
                                              '$currentCount/$limit',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      isFull 
                                          ? 'Role is full' 
                                          : _getRoleDescription(role),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isFull ? AppColors.error : AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ] else ...[
              NeoCard(
                color: AppColors.secondary.withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 32),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solo Project',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Work on this project independently at your own pace',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacingXL),

            // Join Button
            NeoButton(
              text: _isLoading ? 'Joining...' : 'Join Project',
              onPressed: _isLoading ? () {} : _joinProject,
              color: AppColors.primary,
            ),
          ],
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

  String _getRoleDescription(String role) {
    switch (role) {
      case 'frontend':
        return 'Build user interfaces and client-side logic';
      case 'backend':
        return 'Develop server-side APIs and database logic';
      case 'uiux':
        return 'Design user experience and visual interfaces';
      case 'pm':
        return 'Manage project timeline and coordinate team';
      case 'fullstack':
        return 'Work on both frontend and backend development';
      default:
        return 'Contribute to the project';
    }
  }
}
