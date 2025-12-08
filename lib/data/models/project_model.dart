class ProjectModel {
  final String id;
  final String code; // V2: 6-character unique code for joining
  final String title;
  final String description;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? thumbnailUrl;
  final String createdByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String mode; // 'solo' or 'multiplayer'
  final List<String>? requiredRoles; // For team projects
  final Map<String, dynamic>? roleLimits; // Max count for each role
  final bool requiresApproval; // V2: PM must approve join requests
  final DateTime? deletedAt; // V2: Soft delete support
  final List<Map<String, dynamic>>? joinedUsers; // Users who joined the project
  final bool isCompleted; // If any user has completed this project

  ProjectModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.difficulty = 'medium',
    this.thumbnailUrl,
    required this.createdByAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.mode = 'solo',
    this.requiredRoles,
    this.roleLimits,
    this.requiresApproval = false,
    this.deletedAt,
    this.joinedUsers,
    this.isCompleted = false,
  });

  // V2: Calculate max members from roleLimits
  int get calculatedMaxMembers {
    if (mode == 'solo') return 1;
    if (roleLimits == null || roleLimits!.isEmpty) return 0;
    
    int total = 0;
    roleLimits!.forEach((role, limit) {
      if (limit is int) {
        total += limit;
      } else if (limit is num) {
        total += limit.toInt();
      }
    });
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'thumbnail_url': thumbnailUrl,
      'created_by_admin': createdByAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'mode': mode,
      'required_roles': requiredRoles,
      'role_limits': roleLimits,
      'requires_approval': requiresApproval,
      'deleted_at': deletedAt?.toIso8601String(),
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

    // Parse role_limits with better error handling
    Map<String, dynamic>? roleLimits;
    if (json['role_limits'] != null) {
      try {
        roleLimits = Map<String, dynamic>.from(json['role_limits'] as Map);
      } catch (e) {
        print('Error parsing role_limits for project ${json['title']}: $e');
        roleLimits = null;
      }
    }

    return ProjectModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
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
      roleLimits: roleLimits,
      requiresApproval: json['requires_approval'] ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      joinedUsers: users,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? difficulty,
    String? thumbnailUrl,
    String? createdByAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mode,
    List<String>? requiredRoles,
    Map<String, dynamic>? roleLimits,
    bool? requiresApproval,
    DateTime? deletedAt,
    List<Map<String, dynamic>>? joinedUsers,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mode: mode ?? this.mode,
      requiredRoles: requiredRoles ?? this.requiredRoles,
      roleLimits: roleLimits,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      deletedAt: deletedAt ?? this.deletedAt,
      joinedUsers: joinedUsers ?? this.joinedUsers,
    );
  }
}
