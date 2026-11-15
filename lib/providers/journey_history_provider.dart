import 'package:flutter/material.dart';
import '../data/models/journey.dart';
import '../data/repositories/local_storage_repository.dart';

class JourneyHistoryProvider with ChangeNotifier {
  final LocalStorageRepository _repository;
  List<Journey> _history = [];
  bool _isLoading = true;

  JourneyHistoryProvider(this._repository) {
    _loadHistory();
  }

  List<Journey> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _history = await _repository.loadJourneyHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> recordJourney(Journey journey) async {
    _history.insert(0, journey);
    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }
    notifyListeners();
    await _repository.saveJourneyHistory(_history);
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await _repository.saveJourneyHistory(_history);
  }
}

