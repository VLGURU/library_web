import '../models/publisher.dart';

abstract interface class PublisherRepository {
  Future<List<Publisher>> all({bool includeDeleted = false});
  Future<Publisher?> findById(int id);
  Future<Publisher> create(Publisher publisher);
  Future<Publisher> update(Publisher publisher);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
}