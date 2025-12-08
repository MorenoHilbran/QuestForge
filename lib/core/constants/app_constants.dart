class AppConstants {
  // App Info
  static const String appName = 'QuestForge';
  static const String appVersion = '1.0.0';
  
  // Neobrutalism Style Constants
  static const double borderWidth = 3.0;
  static const double borderWidthThick = 4.0;
  static const double borderRadius = 8.0;
  static const double shadowOffset = 4.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  
  // Project Roles
  static const List<String> projectRoles = [
    'frontend',
    'backend',
    'uiux',
    'pm',
    'fullstack',
  ];
  
  static const Map<String, String> projectRoleLabels = {
    'frontend': 'Frontend Developer',
    'backend': 'Backend Developer',
    'uiux': 'UI/UX Designer',
    'pm': 'Project Manager',
    'fullstack': 'Fullstack Developer',
  };
  
  // Project Difficulty
  static const List<String> projectDifficulty = [
    'easy',
    'medium',
    'hard',
  ];
  
  // Project Mode
  static const String modeSolo = 'solo';
  static const String modeMultiplayer = 'multiplayer';
  
  // Task Status (V2 Schema)
  static const String taskTodo = 'todo';
  static const String taskInProgress = 'in_progress';
  static const String taskDone = 'done';
  
  static const List<String> taskStatus = [
    taskTodo,
    taskInProgress,
    taskDone,
  ];
  
  static const Map<String, String> taskStatusLabels = {
    'todo': 'To Do',
    'in_progress': 'In Progress',
    'done': 'Done',
  };
  
  // Task Priority (V2 Schema)
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  
  static const List<String> taskPriority = [
    priorityLow,
    priorityMedium,
    priorityHigh,
  ];
  
  static const Map<String, String> taskPriorityLabels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
  };
  
  // User Project Status (V2 Schema)
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusDropped = 'dropped';
  
  // Approval Status (V2 Schema - NEW!)
  static const String approvalPending = 'pending';
  static const String approvalApproved = 'approved';
  static const String approvalRejected = 'rejected';
  
  static const List<String> approvalStatuses = [
    approvalPending,
    approvalApproved,
    approvalRejected,
  ];
  
  static const Map<String, String> approvalStatusLabels = {
    'pending': 'Pending Approval',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };
  
  // Activity Actions (V2 Schema - NEW!)
  static const String actionProjectCreated = 'project_created';
  static const String actionProjectUpdated = 'project_updated';
  static const String actionProjectDeleted = 'project_deleted';
  static const String actionUserJoined = 'user_joined';
  static const String actionUserApproved = 'user_approved';
  static const String actionUserRejected = 'user_rejected';
  static const String actionUserLeft = 'user_left';
  static const String actionTaskCreated = 'task_created';
  static const String actionTaskUpdated = 'task_updated';
  static const String actionTaskCompleted = 'task_completed';
  static const String actionTaskClaimed = 'task_claimed';
  static const String actionMilestoneCreated = 'milestone_created';
  static const String actionMilestoneCompleted = 'milestone_completed';
  static const String actionBadgeEarned = 'badge_earned';
  
  static const List<String> activityActions = [
    actionProjectCreated,
    actionProjectUpdated,
    actionProjectDeleted,
    actionUserJoined,
    actionUserApproved,
    actionUserRejected,
    actionUserLeft,
    actionTaskCreated,
    actionTaskUpdated,
    actionTaskCompleted,
    actionTaskClaimed,
    actionMilestoneCreated,
    actionMilestoneCompleted,
    actionBadgeEarned,
  ];
  
  static const Map<String, String> activityActionLabels = {
    'project_created': 'Created Project',
    'project_updated': 'Updated Project',
    'project_deleted': 'Deleted Project',
    'user_joined': 'Joined Project',
    'user_approved': 'Approved User',
    'user_rejected': 'Rejected User',
    'user_left': 'Left Project',
    'task_created': 'Created Task',
    'task_updated': 'Updated Task',
    'task_completed': 'Completed Task',
    'task_claimed': 'Claimed Task',
    'milestone_created': 'Created Milestone',
    'milestone_completed': 'Completed Milestone',
    'badge_earned': 'Earned Badge',
  };
  
  // SharedPreferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserAvatar = 'user_avatar';
  static const String keyIsAdmin = 'is_admin';
  static const String keyIsLoggedIn = 'is_logged_in';
  
  // Project Code Length
  static const int projectCodeLength = 6;
}
