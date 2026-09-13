import 'package:dio/dio.dart';

import '../core/api_debug_params.dart';
import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;
  ApiBookRepository(this._dio);

  CancelToken? _findCancelToken;

  @override
  Future<PageResult<Book>> find(BookQuery q) => guard(() async {
        _findCancelToken?.cancel('stale');
        final token = CancelToken();
        _findCancelToken = token;

        return retryRead(() async {
          final response = await _dio.get(
            '/books',
            cancelToken: token,
            queryParameters: <String, dynamic>{
              if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
              if (q.genreId != null) 'genreId': q.genreId,
              if (q.publisherId != null) 'publisherId': q.publisherId,
              if (q.yearFrom != null) 'yearFrom': q.yearFrom,
              if (q.yearTo != null) 'yearTo': q.yearTo,
              'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
              'page': q.page,
              'size': q.size,
              if (q.includeDeleted) 'includeDeleted': true,
              ...apiDebugParamsFromUrl(), // ✅ вызов функции
            },
          );

          final data = (response.data as Map).cast<String, dynamic>();
          return PageResult<Book>(
            items: (data['items'] as List? ?? const [])
                .whereType<Map>()
                .map((e) => Book.fromJson(e.cast<String, dynamic>()))
                .toList(),
            page: (data['page'] as num?)?.toInt() ?? q.page,
            size: (data['size'] as num?)?.toInt() ?? q.size,
            total: (data['total'] as num?)?.toInt() ?? 0,
          );
        });
      });

  @override
  Future<Book?> findById(int id) => guard(() async {
        try {
          return await retryRead(() async {
            final response = await _dio.get(
              '/books/$id',
              queryParameters: apiDebugParamsFromUrl(), // ✅
            );
            return Book.fromJson((response.data as Map).cast<String, dynamic>());
          });
        } on NotFoundException {
          return null;
        }
      });

  Map<String, dynamic> _bookInput(Book book) => {
        'title': book.title,
        'isbn': book.isbn,
        'year': book.year,
        'pages': book.pages,
        'publisherId': book.publisherId,
        'authorIds': book.authorIds,
        'genreIds': book.genreIds,
        'copiesTotal': book.copiesTotal,
      };

  @override
  Future<Book> create(Book book) => guard(() async {
        final response = await _dio.post(
          '/books',
          queryParameters: apiDebugParamsFromUrl(), // ✅
          data: _bookInput(book),
        );
        return Book.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<Book> update(Book book) => guard(() async {
        final response = await _dio.put(
          '/books/${book.id}',
          queryParameters: apiDebugParamsFromUrl(), // ✅
          data: _bookInput(book),
        );
        return Book.fromJson((response.data as Map).cast<String, dynamic>());
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        await _dio.delete(
          '/books/$id',
          queryParameters: apiDebugParamsFromUrl(), // ✅
        );
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        await _dio.delete(
          '/books/$id',
          queryParameters: {
            'hard': true,
            ...apiDebugParamsFromUrl(), // ✅
          },
        );
      });

  @override
  Future<void> restore(int id) => guard(() async {
        await _dio.post(
          '/books/$id/restore',
          queryParameters: apiDebugParamsFromUrl(), // ✅
        );
      });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post(
          '/books/bulk-delete',
          queryParameters: apiDebugParamsFromUrl(), // ✅
          data: {'ids': ids},
        );
        final data = (response.data as Map).cast<String, dynamic>();
        return (data['deleted'] as num?)?.toInt() ?? 0;
      });
}