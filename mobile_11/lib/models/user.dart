class User {
  final String id;
  final String email;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final String? currentJobId;

  User({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    this.currentJobId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      emailVerified: json['emailVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
      isActive: json['isActive'] ?? true,
      currentJobId: json['currentJob'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
      'currentJob': currentJobId,
    };
  }
}
