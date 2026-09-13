// lib/repositories/api_author_repository.dart
import 'package:dio/dio.dart';

import '../core/api_debug_params.dart';
import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;
  ApiAuthorRepository(this._dio);

  CancelToken? _findCancelToken;

  // "5": кэш результатов запросов авторов (в т.ч. справочник для форм)
  final Map<AuthorQuery, PageResult<Author>> _cache = {};

  void _invalidateCache() => _cache.clear();

  Map<String, dynamic> _authorInput(Author author) {
    final map = Map<String, dynamic>.from(author.toJson());
    map.remove('id');
    map.remove('deletedAt');
    map.removeWhere((k, v) => v == null);
    return map;
  }

  Map<String, dynamic> _authorQueryParams(AuthorQuery q) {
    final base = <String, dynamic>{};

    // ожидаем, что AuthorQuery умеет формировать параметры как BookQuery
    final qp = q.toQueryParameters(); // Map<String, String>
    for (final e in qp.entries) {
      base[e.key] = e.value;
    }

    // если includeDeleted приходит как "1" — переводим в true
    if (base['includeDeleted'] == '1') {
      base['includeDeleted'] = true;
    } else {
      base.remove('includeDeleted');
    }

    return {...base, ...apiDebugParamsFromUrl()};
  }

  @override
  Future<PageResult<Author>> find(AuthorQuery query) => guard(() async {
        final cached = _cache[query];
        if (cached != null) return cached;

        _findCancelToken?.cancel('stale');
        final token = CancelToken();
        _findCancelToken = token;

        final result = await retryRead(() async {
          final response = await _dio.get(
            '/authors',
            cancelToken: token,
            queryParameters: _authorQueryParams(query),
          );

          final data = (response.data as Map).cast<String, dynamic>();
          return PageResult<Author>(
            items: (data['items'] as List? ?? const [])
                .whereType<Map>()
                .map((e) => Author.fromJson(e.cast<String, dynamic>()))
                .toList(),
            page: (data['page'] as num?)?.toInt() ?? 1,
            size: (data['size'] as num?)?.toInt() ?? 10,
            total: (data['total'] as num?)?.toInt() ?? 0,
          );
        });

        // кэшируем только не-deleted выдачу
        // (если хочешь — можно кэшировать вообще всё)
        _cache[query] = result;
        return result;
      });

  @override
  Future<Author?> findById(int id) => guard(() async {
        try {
          return await retryRead(() async {
            final response = await _dio.get(
              '/authors/$id',
              queryParameters: apiDebugParamsFromUrl(),
            );
            return Author.fromJson((response.data as Map).cast<String, dynamic>());
          });
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Author> create(Author author) => guard(() async {
        final response = await _dio.post(
          '/authors',
          queryParameters: apiDebugParamsFromUrl(),
          data: _authorInput(author),
        );
        _invalidateCache();
        return Author.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<Author> update(Author author) => guard(() async {
        final response = await _dio.put(
          '/authors/${author.id}',
          queryParameters: apiDebugParamsFromUrl(),
          data: _authorInput(author),
        );
        _invalidateCache();
        return Author.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete(
          '/authors/$id',
          queryParameters: apiDebugParamsFromUrl(),
        );
        _invalidateCache();
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete(
          '/authors/$id',
          queryParameters: {'hard': true, ...apiDebugParamsFromUrl()},
        );
        _invalidateCache();
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post(
          '/authors/$id/restore',
          queryParameters: apiDebugParamsFromUrl(),
        );
        _invalidateCache();
      });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post(
          '/authors/bulk-delete',
          queryParameters: apiDebugParamsFromUrl(),
          data: {'ids': ids},
        );
        _invalidateCache();
        final data = (response.data as Map).cast<String, dynamic>();
        return (data['deleted'] as num?)?.toInt() ?? 0;
      });
}