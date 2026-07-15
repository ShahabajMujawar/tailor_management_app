/// Business entity representing an application user.
class User {
  final int id;
  final String username;
  final String role;

  const User({
    required this.id,
    required this.username,
    required this.role,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ role.hashCode;
}
