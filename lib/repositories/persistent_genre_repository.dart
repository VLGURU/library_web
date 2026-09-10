import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/genre.dart';
import '../seed/seed_data.dart';
import 'genre_repository.dart';

class PersistentGenreRepository implements GenreRepository {
  static const _key = 'genres_v1';
  final SharedPreferences _prefs;

  List<Genre> _items = [];
  int _nextId = 1;

  PersistentGenreRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = seedGenres.map((g) => Genre(id: g.id, name: g.name)).toList();
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _persist();
      return;
    }

    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Genre.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _items = list;
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
    } catch (_) {
      _items = seedGenres.map((g) => Genre(id: g.id, name: g.name)).toList();
      _nextId = (_items.map((e) => e.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<Genre>> all({bool includeDeleted = false}) async {
    final rows = includeDeleted ? _items : _items.where((e) => !e.isDeleted).toList();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  @override
  Future<Genre?> findById(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    return i == -1 ? null : _items[i];
  }

  @override
  Future<Genre> create(Genre genre) async {
    final created = Genre(id: _nextId++, name: genre.name.trim());
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final i = _items.indexWhere((e) => e.id == genre.id);
    if (i == -1) throw StateError('Жанр не найден');
    _items[i] = genre.copyWith(name: genre.name.trim());
    await _persist();
    return _items[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError('Жанр не найден');
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
    if (i == -1) throw StateError('Жанр не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }
}