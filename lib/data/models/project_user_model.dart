class ProjectUserModel {
  final String id;
  final String projectId;
  final String userId;
  final String role; // 'solo', 'frontend', 'backend', 'uiux', 'pm', 'fullstack'
  final String approvalStatus; // V2: 'pending', 'approved', 'rejected'
  final String? approvedBy; // V2: User ID who approved
  final DateTime? approvedAt; // V2: When approved
  final double progress; // 0-100 (auto-calculated in V2)
  final String status; // 'in_progress', 'completed', 'dropped'
  final DateTime joinedAt;
  final DateTime? completedAt;

  ProjectUserModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.approvalStatus = 'approved',
    this.approvedBy,
    this.approvedAt,
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
      'approval_status': approvalStatus,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
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
      approvalStatus: json['approval_status'] ?? 'approved',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
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
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
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
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
