import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/publisher.dart';
import '../seed/seed_data.dart';
import 'publisher_repository.dart';

class PersistentPublisherRepository implements PublisherRepository {
  static const _key = 'publishers_v1';
  final SharedPreferences _prefs;

  List<Publisher> _items = [];
  int _nextId = 1;

  PersistentPublisherRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = seedPublishers.map((p) => Publisher(id: p.id, name: p.name)).toList();
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _persist();
      return;
    }

    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Publisher.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _items = list;
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
    } catch (_) {
      _items = seedPublishers.map((p) => Publisher(id: p.id, name: p.name)).toList();
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<Publisher>> all({bool includeDeleted = false}) async {
    final rows = includeDeleted ? _items : _items.where((e) => !e.isDeleted).toList();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  @override
  Future<Publisher?> findById(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    return i == -1 ? null : _items[i];
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final created = Publisher(id: _nextId++, name: publisher.name.trim());
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final i = _items.indexWhere((e) => e.id == publisher.id);
    if (i == -1) throw StateError('Издательство не найдено');
    _items[i] = publisher.copyWith(name: publisher.name.trim());
    await _persist();
    return _items[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError('Издательство не найдено');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((e) => e.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError('Издательство не найдено');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }
}