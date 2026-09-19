import 'role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'role': role.toJson(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        username: json['username'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        role: Role.fromJson(json['role']),
      );
}