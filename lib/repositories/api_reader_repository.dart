// lib/repositories/api_reader_repository.dart
import 'package:dio/dio.dart';

import '../core/api_debug_params.dart';
import '../core/api_exceptions.dart';
import '../models/reader.dart';
import 'reader_repository.dart';

class ApiReaderRepository implements ReaderRepository {
  final Dio _dio;
  ApiReaderRepository(this._dio);

  List<Reader>? _cacheAll;

  void _invalidateCache() => _cacheAll = null;

  Map<String, dynamic> _readerInput(Reader reader) {
    final map = Map<String, dynamic>.from(reader.toJson());
    map.remove('id');
    map.remove('deletedAt');
    map.removeWhere((k, v) => v == null);
    return map;
  }

  @override
  Future<List<Reader>> all({bool includeDeleted = false}) => guard(() async {
        if (!includeDeleted && _cacheAll != null) return _cacheAll!;

        final result = await retryRead(() async {
          final response = await _dio.get(
            '/readers',
            queryParameters: {
              if (includeDeleted) 'includeDeleted': true,
              ...apiDebugParamsFromUrl(),
            },
          );

          final list = response.data as List? ?? const [];
          return list
              .whereType<Map>()
              .map((e) => Reader.fromJson(e.cast<String, dynamic>()))
              .toList();
        });

        if (!includeDeleted) _cacheAll = result;
        return result;
      });

  @override
  Future<Reader?> findById(int id) => guard(() async {
        try {
          return await retryRead(() async {
            final response = await _dio.get(
              '/readers/$id',
              queryParameters: apiDebugParamsFromUrl(),
            );
            return Reader.fromJson((response.data as Map).cast<String, dynamic>());
          });
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Reader> create(Reader reader) => guard(() async {
        final response = await _dio.post(
          '/readers',
          queryParameters: apiDebugParamsFromUrl(),
          data: _readerInput(reader),
        );
        _invalidateCache();
        return Reader.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<Reader> update(Reader reader) => guard(() async {
        final response = await _dio.put(
          '/readers/${reader.id}',
          queryParameters: apiDebugParamsFromUrl(),
          data: _readerInput(reader),
        );
        _invalidateCache();
        return Reader.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete('/readers/$id', queryParameters: apiDebugParamsFromUrl());
        _invalidateCache();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete(
          '/readers/$id',
          queryParameters: {'hard': true, ...apiDebugParamsFromUrl()},
        );
        _invalidateCache();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post('/readers/$id/restore', queryParameters: apiDebugParamsFromUrl());
        _invalidateCache();
      });
}