class Profile {
  final String id;
  final String userId;
  final String displayName;

  const Profile({
    required this.id,
    required this.userId,
    required this.displayName,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      displayName: (map['nome_social'] ?? map['nome_completo'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nome_social': displayName,
      'nome_completo': displayName,
    };
  }
}
