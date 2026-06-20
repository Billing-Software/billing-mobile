class User {
  final String username;
  final String email;
  final String role;
  final int businessId;
  final String businessName;
  final String? name;
  final String? avatarUrl;
  final String? token;

  User({
    required this.username,
    required this.email,
    required this.role,
    required this.businessId,
    required this.businessName,
    this.name,
    this.avatarUrl,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      businessId: json['businessId'] ?? 0,
      businessName: json['businessName'] ?? '',
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'businessId': businessId,
      'businessName': businessName,
      'name': name,
      'avatarUrl': avatarUrl,
      'token': token,
    };
  }
}
