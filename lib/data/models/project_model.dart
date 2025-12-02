class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? thumbnailUrl;
  final String createdByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String mode; // 'solo' or 'multiplayer'
  final List<String>? requiredRoles; // For team projects
  final List<Map<String, dynamic>>? joinedUsers; // Users who joined the project
  final bool isCompleted; // If any user has completed this project

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    this.difficulty = 'medium',
    this.thumbnailUrl,
    required this.createdByAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.mode = 'solo',
    this.requiredRoles,
    this.joinedUsers,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'thumbnail_url': thumbnailUrl,
      'created_by_admin': createdByAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'mode': mode,
      'required_roles': requiredRoles,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Extract joined users from user_projects relation
    List<Map<String, dynamic>>? users;
    if (json['user_projects'] != null) {
      final userProjects = json['user_projects'] as List;
      users = userProjects
          .where((up) => up['profiles'] != null)
          .map((up) => up['profiles'] as Map<String, dynamic>)
          .toList();
    }

    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      thumbnailUrl: json['thumbnail_url'],
      createdByAdmin: json['created_by_admin'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      mode: json['mode'] ?? 'solo',
      requiredRoles: json['required_roles'] != null
          ? List<String>.from(json['required_roles'])
          : null,
      joinedUsers: users,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? difficulty,
    String? thumbnailUrl,
    String? createdByAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mode,
    List<String>? requiredRoles,
    List<Map<String, dynamic>>? joinedUsers,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mode: mode ?? this.mode,
      requiredRoles: requiredRoles ?? this.requiredRoles,
      joinedUsers: joinedUsers ?? this.joinedUsers,
    );
  }
}
