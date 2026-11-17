import 'package:flutter/material.dart';
import '../data/models/destination.dart';
import '../data/repositories/local_storage_repository.dart';

class SavedDestinationsProvider with ChangeNotifier {
  final LocalStorageRepository _repository;
  List<Destination> _destinations = [];
  List<Destination> _recentSearches = [];
  bool _isLoading = true;

  SavedDestinationsProvider(this._repository) {
    _loadDestinations();
  }

  List<Destination> get destinations => List.unmodifiable(_destinations);
  List<Destination> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isLoading => _isLoading;

  Future<void> _loadDestinations() async {
    _isLoading = true;
    notifyListeners();
    final loaded = await _repository.loadSavedDestinations();
    final recents = await _repository.loadRecentSearches();
    for (final item in _destinations) {
      if (!loaded.any((d) => d.id == item.id)) {
        loaded.insert(0, item);
      }
    }
    for (final item in _recentSearches) {
      if (!recents.any((d) => d.name == item.name)) {
        recents.insert(0, item);
      }
    }
    _destinations = loaded;
    _recentSearches = recents;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDestination(Destination destination) async {
    if (_isLoading) {
      await _loadDestinations();
    }
    // Avoid duplicates by coordinates and name
    final existingIndex = _destinations.indexWhere((d) =>
        d.id == destination.id ||
        (d.latitude == destination.latitude &&
            d.longitude == destination.longitude));

    if (existingIndex >= 0) {
      _destinations[existingIndex] = destination;
    } else {
      _destinations.insert(0, destination);
    }
    notifyListeners();
    await _repository.saveSavedDestinations(_destinations);
  }

  Future<void> updateDestination(Destination destination) async {
    final index = _destinations.indexWhere((d) => d.id == destination.id);
    if (index >= 0) {
      _destinations[index] = destination;
      notifyListeners();
      await _repository.saveSavedDestinations(_destinations);
    }
  }

  Future<void> deleteDestination(String id) async {
    _destinations.removeWhere((d) => d.id == id);
    notifyListeners();
    await _repository.saveSavedDestinations(_destinations);
  }

  Future<void> clearAllDestinations() async {
    _destinations.clear();
    notifyListeners();
    await _repository.clearSavedDestinations();
  }

  Future<void> addRecentSearch(Destination destination) async {
    await _repository.addRecentSearch(destination);
    _recentSearches = await _repository.loadRecentSearches();
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    await _repository.clearRecentSearches();
    _recentSearches = [];
    notifyListeners();
  }
}

