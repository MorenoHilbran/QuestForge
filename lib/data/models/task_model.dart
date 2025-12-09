class TaskModel {
  final String id;
  final String projectId;
  final String? milestoneId; // V2: Link to milestone
  final String title;
  final String? description;
  final String? assignedRole;
  final String? assignedUserId; // V2: Specific user who claimed this task
  final DateTime? claimedAt; // V2: When task was claimed
  final String status; // 'todo', 'in_progress', 'done'
  final String priority; // 'low', 'medium', 'high'
  final DateTime? dueDate; // V2: Changed from deadline to due_date
  final String createdBy; // V2: User who created the task
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.projectId,
    this.milestoneId,
    required this.title,
    this.description,
    this.assignedRole,
    this.assignedUserId,
    this.claimedAt,
    this.status = 'todo',
    this.priority = 'medium',
    this.dueDate,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'milestone_id': milestoneId,
      'title': title,
      'description': description,
      'assigned_role': assignedRole,
      'assigned_user_id': assignedUserId,
      'claimed_at': claimedAt?.toIso8601String(),
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? json['projectId'] ?? '',
      milestoneId: json['milestone_id'],
      title: json['title'] ?? '',
      description: json['description'],
      assignedRole: json['assigned_role'] ?? json['assignedRole'],
      assignedUserId: json['assigned_user_id'],
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'])
          : null,
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : (json['deadline'] != null ? DateTime.parse(json['deadline']) : null),
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now()),
    );
  }

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? milestoneId,
    String? title,
    String? description,
    String? assignedRole,
    String? assignedUserId,
    DateTime? claimedAt,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      milestoneId: milestoneId ?? this.milestoneId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedRole: assignedRole ?? this.assignedRole,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      claimedAt: claimedAt ?? this.claimedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
