// lib/repositories/api_genre_repository.dart
import 'package:dio/dio.dart';

import '../core/api_debug_params.dart';
import '../core/api_exceptions.dart';
import '../models/genre.dart';
import 'genre_repository.dart';

class ApiGenreRepository implements GenreRepository {
  final Dio _dio;
  ApiGenreRepository(this._dio);

  List<Genre>? _cacheAll;

  void _invalidateCache() => _cacheAll = null;

  Map<String, dynamic> _genreInput(Genre genre) {
    final map = Map<String, dynamic>.from(genre.toJson());
    map.remove('id');
    map.remove('deletedAt');
    map.removeWhere((k, v) => v == null);
    return map;
  }

  @override
  Future<List<Genre>> all({bool includeDeleted = false}) => guard(() async {
        if (!includeDeleted && _cacheAll != null) return _cacheAll!;

        final result = await retryRead(() async {
          final response = await _dio.get(
            '/genres',
            queryParameters: {
              if (includeDeleted) 'includeDeleted': true,
              ...apiDebugParamsFromUrl(),
            },
          );

          final list = response.data as List? ?? const [];
          return list
              .whereType<Map>()
              .map((e) => Genre.fromJson(e.cast<String, dynamic>()))
              .toList();
        });

        if (!includeDeleted) _cacheAll = result;
        return result;
      });

  @override
  Future<Genre?> findById(int id) => guard(() async {
        try {
          return await retryRead(() async {
            final response = await _dio.get(
              '/genres/$id',
              queryParameters: apiDebugParamsFromUrl(),
            );
            return Genre.fromJson((response.data as Map).cast<String, dynamic>());
          });
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Genre> create(Genre genre) => guard(() async {
        final response = await _dio.post(
          '/genres',
          queryParameters: apiDebugParamsFromUrl(),
          data: _genreInput(genre),
        );
        _invalidateCache();
        return Genre.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<Genre> update(Genre genre) => guard(() async {
        final response = await _dio.put(
          '/genres/${genre.id}',
          queryParameters: apiDebugParamsFromUrl(),
          data: _genreInput(genre),
        );
        _invalidateCache();
        return Genre.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete('/genres/$id', queryParameters: apiDebugParamsFromUrl());
        _invalidateCache();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete(
          '/genres/$id',
          queryParameters: {'hard': true, ...apiDebugParamsFromUrl()},
        );
        _invalidateCache();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post('/genres/$id/restore', queryParameters: apiDebugParamsFromUrl());
        _invalidateCache();
      });
}