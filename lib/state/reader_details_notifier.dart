import 'package:flutter/foundation.dart';

import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import 'load_status.dart';

class ReaderDetailsNotifier extends ChangeNotifier {
  final ReaderRepository _repo;
  final int id;

  ReaderDetailsNotifier(this._repo, this.id);

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Reader? _reader;

  LoadStatus get status => _status;
  String? get error => _error;
  Reader? get reader => _reader;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _reader = await _repo.findById(id);
      if (_reader == null) {
        _status = LoadStatus.error;
        _error = 'Читатель не найден';
      } else {
        _status = LoadStatus.success;
      }
    } catch (e) {
      _status = LoadStatus.error;
      _error = 'Ошибка загрузки: $e';
    }

    notifyListeners();
  }
}