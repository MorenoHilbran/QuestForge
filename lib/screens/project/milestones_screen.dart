import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/milestone_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/neo_card.dart';
import '../../widgets/common/neo_button.dart';
import '../../widgets/common/neo_progress_bar.dart';

class MilestonesScreen extends StatelessWidget {
  final String projectId;

  const MilestonesScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final milestones = projectProvider.getMilestonesByProject(projectId);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;
    final userRole = projectProvider.getUserRoleInProject(
      projectId,
      authProvider.currentUser?.id ?? '',
    );
    final canManage = isAdmin || userRole == 'Project Manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: const Text(
          'Milestones',
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
            if (canManage)
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: NeoButton(
                  text: 'Add Milestone',
                  onPressed: () => _showAddMilestoneDialog(context),
                  color: AppColors.accent,
                  icon: Icons.add,
                ),
              ),
            Expanded(
              child: milestones.isEmpty
                  ? const Center(
                      child: Text(
                        'No milestones yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL,
                      ),
                      itemCount: milestones.length,
                      itemBuilder: (context, index) {
                        final milestone = milestones[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingL,
                          ),
                          child: NeoCard(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.flag,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: AppConstants.spacingM),
                                    Expanded(
                                      child: Text(
                                        milestone.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.spacingM),
                                NeoProgressBar(
                                  progress: milestone.progress,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(height: AppConstants.spacingM),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Status: ${milestone.status}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Due: ${milestone.targetDate.day}/${milestone.targetDate.month}/${milestone.targetDate.year}',
                                      style: const TextStyle(
                                        fontSize: 12,
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

  void _showAddMilestoneDialog(BuildContext context) {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Add Milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Milestone Name'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Target Date'),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final milestone = MilestoneModel(
                    id: const Uuid().v4(),
                    projectId: projectId,
                    name: nameController.text,
                    targetDate: selectedDate,
                  );
                  context.read<ProjectProvider>().addMilestone(milestone);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
