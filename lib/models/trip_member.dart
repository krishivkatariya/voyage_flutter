class TripMember {
  final String userId;
  final String name;
  final String? email;
  final String role;

  const TripMember({
    required this.userId,
    required this.name,
    this.email,
    this.role = 'member',
  });

  String get id => userId;

  factory TripMember.fromMap(
    Map<String, dynamic> map, {
    required String userId,
  }) {
    return TripMember(
      userId: userId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String?,
      role: map['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name, 'email': email, 'role': role};
  }
}
