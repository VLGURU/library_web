import '../models/app_user.dart';

abstract interface class UserRepository {
  Future<List<AppUser>> all();
}