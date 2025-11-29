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
  
  // Roles
  static const List<String> roles = [
    'Frontend',
    'Backend',
    'Project Manager',
    'UI/UX',
  ];
  
  // Task Status
  static const List<String> taskStatus = [
    'To-do',
    'In Progress',
    'Review',
    'Done',
  ];
  
  // Task Priority
  static const List<String> taskPriority = [
    'High',
    'Medium',
    'Low',
  ];
  
  // Milestone Status
  static const List<String> milestoneStatus = [
    'Not Started',
    'In Progress',
    'Completed',
  ];
  
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
