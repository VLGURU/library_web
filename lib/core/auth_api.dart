import 'package:dio/dio.dart';
import '../models/auth_result.dart';
import 'api_exceptions.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<AuthResult> login(String username, String password) => guard(() async {
        final r = await _dio.post('/auth/login', data: {
          'username': username.trim(),
          'password': password,
        });
        return AuthResult.fromJson((r.data as Map).cast<String, dynamic>());
      });

  Future<AuthResult> register({
    required String username,
    required String password,
    required String fullName,
  }) =>
      guard(() async {
        final r = await _dio.post('/auth/register', data: {
          'username': username.trim(),
          'password': password,
          'fullName': fullName.trim(),
        });
        return AuthResult.fromJson((r.data as Map).cast<String, dynamic>());
      });

  Future<AuthResult> refresh(String refreshToken) => guard(() async {
        final r = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
        return AuthResult.fromJson((r.data as Map).cast<String, dynamic>());
      });
}