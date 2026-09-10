import 'package:flutter/foundation.dart';

import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import 'load_status.dart';

class ReaderListNotifier extends ChangeNotifier {
  final ReaderRepository _repo;
  ReaderListNotifier(this._repo);

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<Reader> _items = [];
  bool _includeDeleted = false;

  LoadStatus get status => _status;
  String? get error => _error;
  List<Reader> get items => List.unmodifiable(_items);
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
      _error = 'Не удалось загрузить читателей: $e';
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