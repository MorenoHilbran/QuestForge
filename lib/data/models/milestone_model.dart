class MilestoneModel {
  final String id;
  final String projectId;
  final String title; // V2: Changed from 'name' to 'title'
  final String? description; // V2: Added description field
  final int orderIndex; // V2: Display order within project
  final DateTime? targetDate;
  final bool isCompleted; // V2: Changed from status string to boolean
  final DateTime? completedAt; // V2: When milestone was completed
  final String createdBy; // V2: User who created milestone
  final DateTime createdAt;

  MilestoneModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.orderIndex = 0,
    this.targetDate,
    this.isCompleted = false,
    this.completedAt,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'order_index': orderIndex,
      'target_date': targetDate?.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? json['projectId'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      orderIndex: json['order_index'] ?? 0,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'])
          : (json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null),
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    );
  }

  MilestoneModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    int? orderIndex,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? completedAt,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
