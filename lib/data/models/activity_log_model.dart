class ActivityLogModel {
  final String id;
  final String? userId; // V2: Nullable (allows orphaned logs)
  final String? projectId; // V2: Can be null for non-project activities
  final String action; // V2: 14 predefined actions (see app_constants.dart)
  final String? targetType; // V2: 'project', 'task', 'milestone', 'badge', 'user'
  final String? targetId; // V2: ID of the target entity
  final Map<String, dynamic>? metadata; // V2: Additional context as JSONB
  final DateTime createdAt; // V2: Changed from 'timestamp' to 'created_at'

  ActivityLogModel({
    required this.id,
    this.userId,
    this.projectId,
    required this.action,
    this.targetType,
    this.targetId,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    // Parse metadata safely
    Map<String, dynamic>? parsedMetadata;
    if (json['metadata'] != null) {
      try {
        parsedMetadata = Map<String, dynamic>.from(json['metadata'] as Map);
      } catch (e) {
        print('Error parsing activity log metadata: $e');
        parsedMetadata = null;
      }
    }

    return ActivityLogModel(
      id: json['id'] ?? '',
      userId: json['user_id'],
      projectId: json['project_id'],
      action: json['action'] ?? '',
      targetType: json['target_type'],
      targetId: json['target_id'],
      metadata: parsedMetadata,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['timestamp'] != null 
              ? DateTime.parse(json['timestamp']) 
              : DateTime.now()),
    );
  }

  ActivityLogModel copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
