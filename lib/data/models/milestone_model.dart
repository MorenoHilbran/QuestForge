class MilestoneModel {
  final String id;
  final String projectId;
  final String name;
  final DateTime targetDate;
  final String status;
  final double progress;
  final DateTime createdAt;

  MilestoneModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.targetDate,
    this.status = 'Not Started',
    this.progress = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'targetDate': targetDate.toIso8601String(),
      'status': status,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      name: json['name'] ?? '',
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : DateTime.now(),
      status: json['status'] ?? 'Not Started',
      progress: (json['progress'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  MilestoneModel copyWith({
    String? id,
    String? projectId,
    String? name,
    DateTime? targetDate,
    String? status,
    double? progress,
    DateTime? createdAt,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
