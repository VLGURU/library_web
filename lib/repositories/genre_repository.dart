import '../models/genre.dart';

abstract interface class GenreRepository {
  Future<List<Genre>> all({bool includeDeleted = false});
  Future<Genre?> findById(int id);
  Future<Genre> create(Genre genre);
  Future<Genre> update(Genre genre);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
}