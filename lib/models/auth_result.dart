import 'app_user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        user: AppUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      );
}