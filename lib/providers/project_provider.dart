import 'package:flutter/foundation.dart';
import 'dart:math';
import '../data/models/project_model.dart';
import '../data/models/project_user_model.dart';
import '../data/models/task_model.dart';
import '../data/models/milestone_model.dart';
import '../data/models/activity_log_model.dart';
import '../core/constants/app_constants.dart';

class ProjectProvider with ChangeNotifier {
  final List<ProjectModel> _projects = [];
  final List<ProjectUserModel> _projectUsers = [];
  final List<TaskModel> _tasks = [];
  final List<MilestoneModel> _milestones = [];
  final List<ActivityLogModel> _activityLogs = [];

  List<ProjectModel> get projects => _projects;
  List<ProjectUserModel> get projectUsers => _projectUsers;
  List<TaskModel> get tasks => _tasks;
  List<MilestoneModel> get milestones => _milestones;
  List<ActivityLogModel> get activityLogs => _activityLogs;

  // Project Methods
  String _generateProjectCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        AppConstants.projectCodeLength,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  void addProject(ProjectModel project) {
    final projectWithCode = project.copyWith(
      code: _generateProjectCode(),
    );
    _projects.add(projectWithCode);
    notifyListeners();
  }

  void updateProject(ProjectModel project) {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      notifyListeners();
    }
  }

  void deleteProject(String projectId) {
    _projects.removeWhere((p) => p.id == projectId);
    _projectUsers.removeWhere((pu) => pu.projectId == projectId);
    _tasks.removeWhere((t) => t.projectId == projectId);
    _milestones.removeWhere((m) => m.projectId == projectId);
    _activityLogs.removeWhere((a) => a.projectId == projectId);
    notifyListeners();
  }

  ProjectModel? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  ProjectModel? getProjectByCode(String code) {
    try {
      return _projects.firstWhere((p) => p.code == code);
    } catch (e) {
      return null;
    }
  }

  List<ProjectModel> getProjectsByUserId(String userId) {
    final userProjectIds = _projectUsers
        .where((pu) => pu.userId == userId)
        .map((pu) => pu.projectId)
        .toList();
    return _projects.where((p) => userProjectIds.contains(p.id)).toList();
  }

  // Project User Methods
  void addUserToProject(ProjectUserModel projectUser) {
    _projectUsers.add(projectUser);
    notifyListeners();
  }

  void removeUserFromProject(String projectId, String userId) {
    _projectUsers.removeWhere(
      (pu) => pu.projectId == projectId && pu.userId == userId,
    );
    notifyListeners();
  }

  List<ProjectUserModel> getProjectMembers(String projectId) {
    return _projectUsers.where((pu) => pu.projectId == projectId).toList();
  }

  String? getUserRoleInProject(String projectId, String userId) {
    try {
      final projectUser = _projectUsers.firstWhere(
        (pu) => pu.projectId == projectId && pu.userId == userId,
      );
      return projectUser.role;
    } catch (e) {
      return null;
    }
  }

  // Task Methods
  void addTask(TaskModel task) {
    _tasks.add(task);
    _updateMilestoneProgress(task.projectId);
    notifyListeners();
  }

  void updateTask(TaskModel task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _updateMilestoneProgress(task.projectId);
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    _updateMilestoneProgress(task.projectId);
    notifyListeners();
  }

  List<TaskModel> getTasksByProject(String projectId) {
    return _tasks.where((t) => t.projectId == projectId).toList();
  }

  List<TaskModel> getTasksByProjectAndRole(String projectId, String role) {
    return _tasks
        .where((t) => t.projectId == projectId && t.assignedRole == role)
        .toList();
  }

  // Milestone Methods
  void addMilestone(MilestoneModel milestone) {
    _milestones.add(milestone);
    notifyListeners();
  }

  void updateMilestone(MilestoneModel milestone) {
    final index = _milestones.indexWhere((m) => m.id == milestone.id);
    if (index != -1) {
      _milestones[index] = milestone;
      notifyListeners();
    }
  }

  void deleteMilestone(String milestoneId) {
    _milestones.removeWhere((m) => m.id == milestoneId);
    notifyListeners();
  }

  List<MilestoneModel> getMilestonesByProject(String projectId) {
    return _milestones.where((m) => m.projectId == projectId).toList();
  }

  void _updateMilestoneProgress(String projectId) {
    final projectTasks = getTasksByProject(projectId);
    if (projectTasks.isEmpty) return;

    final completedTasks =
        projectTasks.where((t) => t.status == 'Done').length;
    final progress = (completedTasks / projectTasks.length) * 100;

    final projectMilestones = getMilestonesByProject(projectId);
    for (var milestone in projectMilestones) {
      String status = 'Not Started';
      if (progress > 0 && progress < 100) {
        status = 'In Progress';
      } else if (progress == 100) {
        status = 'Completed';
      }

      updateMilestone(milestone.copyWith(
        progress: progress,
        status: status,
      ));
    }
  }

  // Activity Log Methods
  void addActivityLog(ActivityLogModel log) {
    _activityLogs.add(log);
    notifyListeners();
  }

  List<ActivityLogModel> getActivityLogsByProject(String projectId) {
    final logs = _activityLogs.where((a) => a.projectId == projectId).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  // Helper method to get project statistics
  Map<String, dynamic> getProjectStats(String projectId) {
    final projectTasks = getTasksByProject(projectId);
    final members = getProjectMembers(projectId);
    final projectMilestones = getMilestonesByProject(projectId);

    final completedTasks =
        projectTasks.where((t) => t.status == 'Done').length;
    final progress = projectTasks.isEmpty
        ? 0.0
        : (completedTasks / projectTasks.length) * 100;

    return {
      'totalTasks': projectTasks.length,
      'completedTasks': completedTasks,
      'progress': progress,
      'totalMembers': members.length,
      'totalMilestones': projectMilestones.length,
    };
  }
}
