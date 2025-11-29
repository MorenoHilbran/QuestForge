import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/project_user_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_text_field.dart';
import '../../widgets/common/neo_card.dart';

class JoinProjectScreen extends StatefulWidget {
  const JoinProjectScreen({super.key});

  @override
  State<JoinProjectScreen> createState() => _JoinProjectScreenState();
}

class _JoinProjectScreenState extends State<JoinProjectScreen> {
  final _codeController = TextEditingController();
  String? _selectedRole;
  bool _isSolo = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleJoin() {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter project code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isSolo && _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final projectProvider = context.read<ProjectProvider>();
    final authProvider = context.read<AuthProvider>();
    
    final project = projectProvider.getProjectByCode(_codeController.text);

    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add user to project
    if (_isSolo) {
      // Join as all roles
      for (var role in AppConstants.roles) {
        final projectUser = ProjectUserModel(
          projectId: project.id,
          userId: authProvider.currentUser?.id ?? '',
          role: role,
        );
        projectProvider.addUserToProject(projectUser);
      }
    } else {
      final projectUser = ProjectUserModel(
        projectId: project.id,
        userId: authProvider.currentUser?.id ?? '',
        role: _selectedRole!,
      );
      projectProvider.addUserToProject(projectUser);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully joined ${project.name}!'),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Join Project',
          style: TextStyle(
            fontSize: 24,
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
              NeoTextField(
                label: 'Project Code',
                hint: 'Enter 6-digit code',
                controller: _codeController,
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Solo Mode Toggle
              NeoCard(
                color: AppColors.secondary,
                child: CheckboxListTile(
                  title: const Text(
                    'Solo Project',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: const Text(
                    'Handle all roles yourself',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isSolo,
                  onChanged: (value) {
                    setState(() {
                      _isSolo = value ?? false;
                      if (_isSolo) _selectedRole = null;
                    });
                  },
                  activeColor: AppColors.accent,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              if (!_isSolo) ...[
                const SizedBox(height: AppConstants.spacingL),
                const Text(
                  'Select Role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                ...AppConstants.roles.map((role) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingM,
                    ),
                    child: NeoCard(
                      color: _selectedRole == role
                          ? _getRoleColor(role)
                          : Colors.white,
                      onTap: () {
                        setState(() {
                          _selectedRole = role;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _getRoleIcon(role),
                            color: Colors.black,
                            size: 24,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedRole == role)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.black,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: AppConstants.spacingL),
              NeoButton(
                text: 'Join Project',
                onPressed: _handleJoin,
                color: AppColors.accent,
                icon: Icons.check,
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
