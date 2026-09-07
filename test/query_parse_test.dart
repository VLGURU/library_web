import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/book_query.dart';

void main() {
  test('BookQuery parses sort and paging', () {
    final uri = Uri.parse('/books?search=abc&sort=year,desc&page=3&size=25&includeDeleted=1');
    final q = BookQuery.fromUri(uri);

    expect(q.search, 'abc');
    expect(q.sortField, 'year');
    expect(q.sortAscending, false);
    expect(q.page, 3);
    expect(q.size, 25);
    expect(q.includeDeleted, true);
  });
}