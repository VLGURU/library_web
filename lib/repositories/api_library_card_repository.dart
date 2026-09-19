import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/library_card_item.dart';
import 'library_card_repository.dart';

class ApiLibraryCardRepository implements LibraryCardRepository {
  final Dio _dio;
  ApiLibraryCardRepository(this._dio);

  @override
  Future<List<LibraryCardItem>> mine() => guard(() async {
        final r = await _dio.get('/library-cards/mine');
        final list = (r.data as List? ?? const []);
        return list
            .whereType<Map>()
            .map((e) => LibraryCardItem.fromJson(e.cast<String, dynamic>()))
            .toList();
      });
}