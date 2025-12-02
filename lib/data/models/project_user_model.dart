class ProjectUserModel {
  final String id;
  final String projectId;
  final String userId;
  final String role; // 'frontend', 'backend', 'uiux', 'pm', 'fullstack'
  final String mode; // 'solo' or 'multiplayer'
  final double progress; // 0-100
  final String status; // 'in_progress', 'completed', 'abandoned'
  final DateTime joinedAt;
  final DateTime? completedAt;

  ProjectUserModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.mode = 'multiplayer',
    this.progress = 0.0,
    this.status = 'in_progress',
    required this.joinedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'user_id': userId,
      'role': role,
      'mode': mode,
      'progress': progress,
      'status': status,
      'joined_at': joinedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ProjectUserModel.fromJson(Map<String, dynamic> json) {
    return ProjectUserModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] ?? '',
      mode: json['mode'] ?? 'multiplayer',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'in_progress',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  ProjectUserModel copyWith({
    String? id,
    String? projectId,
    String? userId,
    String? role,
    String? mode,
    double? progress,
    String? status,
    DateTime? joinedAt,
    DateTime? completedAt,
  }) {
    return ProjectUserModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      mode: mode ?? this.mode,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
