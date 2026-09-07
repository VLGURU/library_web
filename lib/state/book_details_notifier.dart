import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import 'load_status.dart';

class BookDetailsNotifier extends ChangeNotifier {
  final BookRepository _repository;
  final int id;

  BookDetailsNotifier(this._repository, this.id);

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Book? _book;

  LoadStatus get status => _status;
  String? get error => _error;
  Book? get book => _book;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _book = await _repository.findById(id);
      if (_book == null) {
        _status = LoadStatus.error;
        _error = 'Книга не найдена';
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