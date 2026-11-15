import 'package:flutter/material.dart';
import '../data/models/destination.dart';
import '../data/repositories/local_storage_repository.dart';

class SavedDestinationsProvider with ChangeNotifier {
  final LocalStorageRepository _repository;
  List<Destination> _destinations = [];
  bool _isLoading = true;

  SavedDestinationsProvider(this._repository) {
    _loadDestinations();
  }

  List<Destination> get destinations => List.unmodifiable(_destinations);
  bool get isLoading => _isLoading;

  Future<void> _loadDestinations() async {
    _isLoading = true;
    notifyListeners();
    _destinations = await _repository.loadSavedDestinations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDestination(Destination destination) async {
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
}

