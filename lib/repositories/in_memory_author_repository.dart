import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import '../seed/seed_data.dart';
import 'author_repository.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  final List<Author> _authors = [...seedAuthors];
  int _nextId = seedAuthors.length + 1;

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (q.search.trim() == '__error__') {
      throw StateError('Симулированная ошибка репозитория');
    }

    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.lastName.toLowerCase().contains(needle) ||
              a.country.toLowerCase().contains(needle))
          .toList();
    }

    if (q.country != null) rows = rows.where((a) => a.country == q.country).toList();

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.compareTo(b.country),
        'firstName' => a.firstName.compareTo(b.firstName),
        _ => a.lastName.compareTo(b.lastName),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _authors.indexWhere((a) => a.id == id);
    return i == -1 ? null : _authors[i];
  }

  @override
  Future<Author> create(Author author) async {
    final created = Author(
      id: _nextId++,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      deletedAt: author.deletedAt,
    );
    _authors.add(created);
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError('Автор ${author.id} не найден');
    _authors[i] = author;
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id);
      if (i != -1 && !_authors[i].isDeleted) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}