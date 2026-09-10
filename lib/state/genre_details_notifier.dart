import 'package:flutter/foundation.dart';

import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import 'load_status.dart';

class GenreDetailsNotifier extends ChangeNotifier {
  final GenreRepository _repo;
  final int id;

  GenreDetailsNotifier(this._repo, this.id);

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Genre? _genre;

  LoadStatus get status => _status;
  String? get error => _error;
  Genre? get genre => _genre;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _genre = await _repo.findById(id);
      if (_genre == null) {
        _status = LoadStatus.error;
        _error = 'Жанр не найден';
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