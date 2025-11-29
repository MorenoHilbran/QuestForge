class ActivityLogModel {
  final String id;
  final String projectId;
  final String message;
  final String userId;
  final String userName;
  final DateTime timestamp;

  ActivityLogModel({
    required this.id,
    required this.projectId,
    required this.message,
    required this.userId,
    required this.userName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'message': message,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      message: json['message'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  ActivityLogModel copyWith({
    String? id,
    String? projectId,
    String? message,
    String? userId,
    String? userName,
    DateTime? timestamp,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
