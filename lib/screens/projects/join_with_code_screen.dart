import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import 'join_project_screen.dart';

class JoinWithCodeScreen extends StatefulWidget {
  const JoinWithCodeScreen({super.key});

  @override
  State<JoinWithCodeScreen> createState() => _JoinWithCodeScreenState();
}

class _JoinWithCodeScreenState extends State<JoinWithCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _findAndJoinProject() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project code')),
      );
      return;
    }

    if (code.length != AppConstants.projectCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project code must be ${AppConstants.projectCodeLength} characters'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find project by code
      final response = await SupabaseService.client
          .from('projects')
          .select()
          .eq('code', code)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project not found. Please check the code.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final project = response;
      final userId = context.read<AuthProvider>().currentUser?.id;

      // Check if user already joined by querying user_projects separately
      final userProjectsResponse = await SupabaseService.client
          .from('user_projects')
          .select()
          .eq('project_id', project['id'])
          .eq('user_id', userId ?? '')
          .maybeSingle();

      final alreadyJoined = userProjectsResponse != null;

      if (alreadyJoined) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already joined this project'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Navigate to join screen
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => JoinProjectScreen(project: project),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join with Code',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.spacingXL),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.border,
                    width: AppConstants.borderWidth,
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingXL),
              
              // Title
              const Text(
                'Enter Project Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppConstants.spacingS),
              
              // Description
              Text(
                'Enter the 6-character code provided by the project creator',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppConstants.spacingXL),
              
              // Code Input
              TextFormField(
                controller: _codeController,
                maxLength: AppConstants.projectCodeLength,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'ABC123',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: AppConstants.borderWidth,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: AppConstants.borderWidth,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: AppConstants.borderWidth * 2,
                    ),
                  ),
                  counterText: '',
                ),
                onFieldSubmitted: (_) => _findAndJoinProject(),
              ),
              
              const SizedBox(height: AppConstants.spacingXL),
              
              // Join Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _findAndJoinProject(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      side: const BorderSide(
                        color: AppColors.border,
                        width: AppConstants.borderWidth,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Find Project',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const Spacer(),
              
              // Help Text
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: AppColors.border,
                    width: AppConstants.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        'Ask the project creator for the project code',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
