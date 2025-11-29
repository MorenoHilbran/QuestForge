class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String assignedRole;
  final String status;
  final String priority;
  final DateTime deadline;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.assignedRole,
    this.status = 'To-do',
    this.priority = 'Medium',
    required this.deadline,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'assignedRole': assignedRole,
      'status': status,
      'priority': priority,
      'deadline': deadline.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      assignedRole: json['assignedRole'] ?? '',
      status: json['status'] ?? 'To-do',
      priority: json['priority'] ?? 'Medium',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : DateTime.now(),
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? assignedRole,
    String? status,
    String? priority,
    DateTime? deadline,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      assignedRole: assignedRole ?? this.assignedRole,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
