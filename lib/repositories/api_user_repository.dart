import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import 'user_repository.dart';

class ApiUserRepository implements UserRepository {
  final Dio _dio;
  ApiUserRepository(this._dio);

  @override
  Future<List<AppUser>> all() => guard(() async {
        final r = await _dio.get('/admin/users');
        final list = (r.data as List? ?? const []);
        return list
            .whereType<Map>()
            .map((e) => AppUser.fromJson(e.cast<String, dynamic>()))
            .toList();
      });
}