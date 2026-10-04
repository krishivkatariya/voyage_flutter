class User {
  final String userId;
  final String name;
  final String email;
  final String? profileImage;

  const User({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImage,
  });

  factory User.fromMap(Map<String, dynamic> map, {required String userId}) {
    return User(
      userId: userId,
      name: map['name'] as String,
      email: map['email'] as String,
      profileImage: map['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'profileImage': profileImage};
  }
}
