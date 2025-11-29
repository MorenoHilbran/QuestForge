class ProjectUserModel {
  final String projectId;
  final String userId;
  final String role;
  final DateTime joinedAt;

  ProjectUserModel({
    required this.projectId,
    required this.userId,
    required this.role,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'userId': userId,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory ProjectUserModel.fromJson(Map<String, dynamic> json) {
    return ProjectUserModel(
      projectId: json['projectId'] ?? '',
      userId: json['userId'] ?? '',
      role: json['role'] ?? '',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  ProjectUserModel copyWith({
    String? projectId,
    String? userId,
    String? role,
    DateTime? joinedAt,
  }) {
    return ProjectUserModel(
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
