import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../repositories/author_repository.dart';
import 'load_status.dart';

class AuthorDetailsNotifier extends ChangeNotifier {
  final AuthorRepository _repository;
  final int id;

  AuthorDetailsNotifier(this._repository, this.id);

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Author? _author;

  LoadStatus get status => _status;
  String? get error => _error;
  Author? get author => _author;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _author = await _repository.findById(id);
      if (_author == null) {
        _status = LoadStatus.error;
        _error = 'Автор не найден';
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