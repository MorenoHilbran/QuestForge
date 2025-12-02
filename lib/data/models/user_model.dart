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
    // Parse badges from user_badges relation
    List<BadgeModel> badgesList = [];
    try {
      if (json['user_badges'] != null) {
        final userBadges = json['user_badges'] as List<dynamic>;
        badgesList = userBadges
            .where((ub) => ub['badges'] != null)
            .map((ub) => BadgeModel.fromJson(ub['badges'] as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing badges: $e');
    }

    try {
      return UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown',
        email: json['email']?.toString() ?? '',
        avatarUrl: json['avatar_url']?.toString(),
        bio: json['bio']?.toString(),
        role: json['role']?.toString() ?? 'user',
        badges: badgesList,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'].toString()) 
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'].toString()) 
            : DateTime.now(),
      );
    } catch (e) {
      print('Error creating UserModel: $e');
      print('JSON data: $json');
      rethrow;
    }
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
      name: json['name']?.toString() ?? 'Unknown Badge',
      description: json['description']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
      category: json['category']?.toString() ?? 'meta',
      tier: json['tier']?.toString(),
      awardedAt: json['awarded_at'] != null 
          ? DateTime.parse(json['awarded_at'].toString())
          : DateTime.now(),
    );
  }
}
