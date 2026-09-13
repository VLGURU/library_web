// lib/repositories/api_publisher_repository.dart
import 'package:dio/dio.dart';

import '../core/api_debug_params.dart';
import '../core/api_exceptions.dart';
import '../models/publisher.dart';
import 'publisher_repository.dart';

class ApiPublisherRepository implements PublisherRepository {
  final Dio _dio;
  ApiPublisherRepository(this._dio);

  List<Publisher>? _cacheAll;

  void _invalidateCache() => _cacheAll = null;

  Map<String, dynamic> _publisherInput(Publisher publisher) {
    final map = Map<String, dynamic>.from(publisher.toJson());
    map.remove('id');
    map.remove('deletedAt');
    map.removeWhere((k, v) => v == null);
    return map;
  }

  @override
  Future<List<Publisher>> all({bool includeDeleted = false}) => guard(() async {
        if (!includeDeleted && _cacheAll != null) return _cacheAll!;

        final result = await retryRead(() async {
          final response = await _dio.get(
            '/publishers',
            queryParameters: {
              if (includeDeleted) 'includeDeleted': true,
              ...apiDebugParamsFromUrl(),
            },
          );

          final list = response.data as List? ?? const [];
          return list
              .whereType<Map>()
              .map((e) => Publisher.fromJson(e.cast<String, dynamic>()))
              .toList();
        });

        if (!includeDeleted) _cacheAll = result;
        return result;
      });

  @override
  Future<Publisher?> findById(int id) => guard(() async {
        try {
          return await retryRead(() async {
            final response = await _dio.get(
              '/publishers/$id',
              queryParameters: apiDebugParamsFromUrl(),
            );
            return Publisher.fromJson((response.data as Map).cast<String, dynamic>());
          });
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Publisher> create(Publisher publisher) => guard(() async {
        final response = await _dio.post(
          '/publishers',
          queryParameters: apiDebugParamsFromUrl(),
          data: _publisherInput(publisher),
        );
        _invalidateCache();
        return Publisher.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<Publisher> update(Publisher publisher) => guard(() async {
        final response = await _dio.put(
          '/publishers/${publisher.id}',
          queryParameters: apiDebugParamsFromUrl(),
          data: _publisherInput(publisher),
        );
        _invalidateCache();
        return Publisher.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete('/publishers/$id', queryParameters: apiDebugParamsFromUrl());
        _invalidateCache();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete(
          '/publishers/$id',
          queryParameters: {'hard': true, ...apiDebugParamsFromUrl()},
        );
        _invalidateCache();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post('/publishers/$id/restore', queryParameters: apiDebugParamsFromUrl());
        _invalidateCache();
      });
}