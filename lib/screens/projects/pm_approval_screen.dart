import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class PMApprovalScreen extends StatefulWidget {
  final String projectId;

  const PMApprovalScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<PMApprovalScreen> createState() => _PMApprovalScreenState();
}

class _PMApprovalScreenState extends State<PMApprovalScreen> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.client
          .from('user_projects')
          .select('''
            *,
            profiles!user_id(id, name, email, avatar_url)
          ''')
          .eq('project_id', widget.projectId)
          .eq('approval_status', AppConstants.approvalPending)
          .order('joined_at', ascending: true);

      setState(() {
        _pendingRequests = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  Future<void> _handleApproval(String userProjectId, bool approve) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client.from('user_projects').update({
        'approval_status': approve ? AppConstants.approvalApproved : AppConstants.approvalRejected,
        'approved_by': userId,
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', userProjectId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Request approved' : 'Request rejected'),
            backgroundColor: approve ? AppColors.success : Colors.orange,
          ),
        );

        // Reload list
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
          'Pending Approvals',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'No pending requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    final profile = request['profiles'] as Map<String, dynamic>?;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(
                          color: AppColors.border,
                          width: AppConstants.borderWidth,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary,
                                  backgroundImage: profile?['avatar_url'] != null
                                      ? NetworkImage(profile!['avatar_url'])
                                      : null,
                                  child: profile?['avatar_url'] == null
                                      ? Text(
                                          (profile?['name'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppConstants.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile?['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profile?['email'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: AppConstants.spacingM),
                            
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingM,
                                vertical: AppConstants.spacingS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: AppConstants.borderWidth,
                                ),
                              ),
                              child: Text(
                                'Role: ${AppConstants.projectRoleLabels[request['role']] ?? request['role']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: AppConstants.spacingM),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleApproval(request['id'], false),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(
                                        color: Colors.red,
                                        width: AppConstants.borderWidth,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.borderRadius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingS),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleApproval(request['id'], true),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.borderRadius,
                                        ),
                                        side: const BorderSide(
                                          color: AppColors.border,
                                          width: AppConstants.borderWidth,
                                        ),
                                      ),
                                    ),
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
    );
  }
}
