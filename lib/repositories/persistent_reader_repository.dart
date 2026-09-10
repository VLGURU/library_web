import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reader.dart';
import '../seed/seed_data.dart';
import 'reader_repository.dart';

class PersistentReaderRepository implements ReaderRepository {
  static const _key = 'readers_v1';
  final SharedPreferences _prefs;

  List<Reader> _items = [];
  int _nextId = 1;

  PersistentReaderRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedReaders];
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _persist();
      return;
    }

    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Reader.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _items = list;
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
    } catch (_) {
      _items = [...seedReaders];
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<Reader>> all({bool includeDeleted = false}) async {
    final rows = includeDeleted ? _items : _items.where((e) => !e.isDeleted).toList();
    rows.sort((a, b) => a.lastName.compareTo(b.lastName));
    return rows;
  }

  @override
  Future<Reader?> findById(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    return i == -1 ? null : _items[i];
  }

  @override
  Future<Reader> create(Reader reader) async {
    final withId = Reader(
      id: _nextId++,
      firstName: reader.firstName.trim(),
      lastName: reader.lastName.trim(),
      email: reader.email.trim(),
      card: reader.card,
      deletedAt: reader.deletedAt,
    );
    _items.add(withId);
    await _persist();
    return withId;
  }

  @override
  Future<Reader> update(Reader reader) async {
    final i = _items.indexWhere((e) => e.id == reader.id);
    if (i == -1) throw StateError('Читатель не найден');
    _items[i] = reader.copyWith(
      firstName: reader.firstName.trim(),
      lastName: reader.lastName.trim(),
      email: reader.email.trim(),
    );
    await _persist();
    return _items[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError('Читатель не найден');
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
    if (i == -1) throw StateError('Читатель не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }
}