import 'package:flutter/foundation.dart';

import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';
import 'load_status.dart';

class PublisherDetailsNotifier extends ChangeNotifier {
  final PublisherRepository _repo;
  final int id;

  PublisherDetailsNotifier(this._repo, this.id);

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Publisher? _publisher;

  LoadStatus get status => _status;
  String? get error => _error;
  Publisher? get publisher => _publisher;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _publisher = await _repo.findById(id);
      if (_publisher == null) {
        _status = LoadStatus.error;
        _error = 'Издательство не найдено';
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