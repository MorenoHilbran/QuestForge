class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = '',
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'isAdmin': isAdmin,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
