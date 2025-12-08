import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class ClaimTaskButton extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback onClaimed;

  const ClaimTaskButton({
    super.key,
    required this.task,
    required this.onClaimed,
  });

  @override
  State<ClaimTaskButton> createState() => _ClaimTaskButtonState();
}

class _ClaimTaskButtonState extends State<ClaimTaskButton> {
  bool _isLoading = false;

  Future<void> _claimTask() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
        ),
        title: const Text(
          'Claim Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Do you want to claim this task? You will be responsible for completing it.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: const Text('Claim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // V2: Update assigned_user_id and claimed_at
      await SupabaseService.client.from('tasks').update({
        'assigned_user_id': userId,
        'claimed_at': DateTime.now().toIso8601String(),
        'status': 'in_progress', // Auto-move to in progress
      }).eq('id', widget.task['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task claimed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Callback to refresh parent
        widget.onClaimed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final assignedUserId = widget.task['assigned_user_id'];
    final isClaimed = assignedUserId != null;
    final isClaimedByMe = assignedUserId == userId;

    // Don't show button if already claimed by someone else
    if (isClaimed && !isClaimedByMe) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: AppColors.warning,
            width: AppConstants.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              'Claimed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    // Show "Claimed by you" badge if claimed by current user
    if (isClaimedByMe) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: AppColors.success,
            width: AppConstants.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 16,
              color: AppColors.success,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              'Claimed by you',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    // Show claim button
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _claimTask,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.assignment_ind, size: 16),
      label: Text(_isLoading ? 'Claiming...' : 'Claim Task'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
        ),
      ),
    );
  }
}
