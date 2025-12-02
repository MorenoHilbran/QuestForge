class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String role; // 'admin' or 'user'
  final List<BadgeModel> badges;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.role = 'user',
    this.badges = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'role': role,
      'badges': badges.map((b) => b.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      role: json['role'] ?? 'user',
      badges: (json['badges'] as List<dynamic>?)
              ?.map((b) => BadgeModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    String? role,
    List<BadgeModel>? badges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BadgeModel {
  final String name;
  final String description;
  final String? iconUrl;
  final String category; // 'role', 'solo', 'team', 'meta'
  final String? tier; // 'junior', 'senior', 'master', 'legend'
  final DateTime awardedAt;

  BadgeModel({
    required this.name,
    required this.description,
    this.iconUrl,
    required this.category,
    this.tier,
    required this.awardedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'category': category,
      'tier': tier,
      'awarded_at': awardedAt.toIso8601String(),
    };
  }

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      category: json['category'],
      tier: json['tier'],
      awardedAt: DateTime.parse(json['awarded_at']),
    );
  }
}
