import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:library_web/core/api_client.dart';
import 'package:library_web/core/api_exceptions.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/api_book_repository.dart';

void main() {
  group('ApiBookRepository', () {
    late Dio dio;
    late DioAdapter adapter;
    late ApiBookRepository repo;

    setUp(() {
      dio = buildDio();
      adapter = DioAdapter(dio: dio);
      dio.httpClientAdapter = adapter;

      repo = ApiBookRepository(dio);
    });

    test('find() parses PageResult', () async {
      final q = const BookQuery(page: 1, size: 10);

      adapter.onGet(
        '/books',
        (server) => server.reply(
          200,
          {
            'items': [
              {
                'id': 1,
                'title': 'Test',
                'isbn': '123',
                'year': 2020,
                'pages': 100,
                'publisherId': 1,
                'authorIds': [1],
                'genreIds': [2],
                'copiesTotal': 5,
                'copiesAvailable': 5,
                'deletedAt': null,
              }
            ],
            'page': 1,
            'size': 10,
            'total': 1,
          },
        ),
        queryParameters: {
          'sort': 'title,asc',
          'page': 1,
          'size': 10,
        },
      );

      final page = await repo.find(q);
      expect(page.items, hasLength(1));
      expect(page.total, 1);
      expect(page.items.first.title, 'Test');
    });

    test('create() throws ValidationException on 422', () async {
      final book = Book(
        id: 0,
        title: 'A',
        isbn: 'DUPLICATE',
        year: 2020,
        pages: 100,
        publisherId: 1,
        authorIds: const [1],
        genreIds: const [2],
        copiesTotal: 1,
        copiesAvailable: 1,
      );

      adapter.onPost(
        '/books',
        (server) => server.reply(
          422,
          {
            'message': 'Ошибка валидации',
            'errors': {'isbn': 'ISBN уже существует'},
          },
        ),
      );

      try {
        await repo.create(book);
        fail('Expected ValidationException');
      } catch (e) {
        expect(e, isA<ValidationException>());
        final ve = e as ValidationException;
        expect(ve.errors['isbn'], contains('существует'));
      }
    });

    test('findById() returns null on 404', () async {
      adapter.onGet(
        '/books/999',
        (server) => server.reply(404, {'message': 'Не найдено'}),
      );

      final book = await repo.findById(999);
      expect(book, isNull);
    });

    test('find() throws ServerException on 500', () async {
      adapter.onGet(
        '/books',
        (server) => server.reply(500, {'message': 'Boom'}),
        queryParameters: {
          'sort': 'title,asc',
          'page': 1,
          'size': 10,
        },
      );

      expect(
        () => repo.find(const BookQuery()),
        throwsA(isA<ServerException>()),
      );
    });

    test('find() throws NetworkException on connectionError', () async {
      adapter.onGet(
        '/books',
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: '/books'),
            type: DioExceptionType.connectionError,
          ),
        ),
        queryParameters: {
          'sort': 'title,asc',
          'page': 1,
          'size': 10,
        },
      );

      expect(
        () => repo.find(const BookQuery()),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}