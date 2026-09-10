import 'package:flutter/foundation.dart';

import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import 'load_status.dart';

class GenreListNotifier extends ChangeNotifier {
  final GenreRepository _repo;
  GenreListNotifier(this._repo);

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<Genre> _items = [];
  bool _includeDeleted = false;

  LoadStatus get status => _status;
  String? get error => _error;
  List<Genre> get items => List.unmodifiable(_items);
  bool get includeDeleted => _includeDeleted;

  Future<void> setIncludeDeleted(bool v) async {
    _includeDeleted = v;
    await load();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.all(includeDeleted: _includeDeleted);
      _status = LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
      _error = 'Не удалось загрузить жанры: $e';
    }
    notifyListeners();
  }

  Future<void> softDelete(int id) async {
    await _repo.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repo.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repo.restore(id);
    await load();
  }
}