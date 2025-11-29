class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String code;
  final String adminId;
  final DateTime deadline;
  final String thumbnail;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.adminId,
    required this.deadline,
    this.thumbnail = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'adminId': adminId,
      'deadline': deadline.toIso8601String(),
      'thumbnail': thumbnail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      code: json['code'] ?? '',
      adminId: json['adminId'] ?? '',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : DateTime.now(),
      thumbnail: json['thumbnail'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    String? adminId,
    DateTime? deadline,
    String? thumbnail,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      adminId: adminId ?? this.adminId,
      deadline: deadline ?? this.deadline,
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
