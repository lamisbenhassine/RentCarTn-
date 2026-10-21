import 'package:flutter/foundation.dart';

import '../data/mock/mock_cars.dart';
import '../data/models/car.dart';
import '../data/models/date_range.dart';
import '../data/models/reservation.dart';
import '../data/repositories/car_repository.dart';
import 'load_state.dart';

enum CarSort { pertinence, prixCroissant, prixDecroissant, marque, annee }

extension CarSortX on CarSort {
  String get label => switch (this) {
        CarSort.pertinence => 'Pertinence',
        CarSort.prixCroissant => 'Prix croissant',
        CarSort.prixDecroissant => 'Prix décroissant',
        CarSort.marque => 'Marque (A-Z)',
        CarSort.annee => 'Plus récentes',
      };
}

/// Catalogue + filtres + CRUD admin du parc.
class CarProvider extends ChangeNotifier {
  CarProvider({CarRepository? repository})
      : _repository = repository ?? CarRepositoryFactory.create();

  final CarRepository _repository;

  List<Car> _cars = [];
  LoadState _state = LoadState.initial;
  String? _errorMessage;

  String _query = '';
  CarCategory? _category;
  final Set<String> _brands = {};
  String? _city;
  double _minPrice = 0;
  double _maxPrice = 1000;
  int? _minSeats;
  bool _onlyAvailable = false;
  CarSort _sort = CarSort.pertinence;
  DateRange? _searchRange;

  List<Car> get allCars => _cars;
  LoadState get state => _state;
  String? get errorMessage => _errorMessage;

  String get query => _query;
  CarCategory? get category => _category;
  Set<String> get selectedBrands => _brands;
  String? get city => _city;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  int? get minSeats => _minSeats;
  bool get onlyAvailable => _onlyAvailable;
  CarSort get sort => _sort;
  DateRange? get searchRange => _searchRange;

  List<String> get availableBrands {
    final brands = _cars.map((c) => c.brand).toSet().toList()..sort();
    return brands;
  }

  double get priceCeiling {
    if (_cars.isEmpty) return 1000;
    return _cars.map((c) => c.pricePerDay).reduce((a, b) => a > b ? a : b);
  }

  int get activeFilterCount {
    var count = 0;
    if (_category != null) count++;
    if (_brands.isNotEmpty) count++;
    if (_city != null) count++;
    if (_minSeats != null) count++;
    if (_onlyAvailable) count++;
    if (_minPrice > 0 || _maxPrice < priceCeiling) count++;
    return count;
  }

  Future<void> load({bool force = false}) async {
    if (_state == LoadState.loading) return;
    if (_cars.isNotEmpty && !force) return;

    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.seedIfEmpty();
      _cars = await _repository.getAll();
      _maxPrice = priceCeiling;
      _state = LoadState.success;
    } catch (_) {
      _errorMessage = "Impossible de charger le catalogue. Réessayez.";
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<Car> create(Car car) async {
    final created = await _repository.create(car);
    _cars = [created, ..._cars];
    notifyListeners();
    return created;
  }

  Future<Car> update(Car car) async {
    final updated = await _repository.update(car);
    _cars = [
      for (final c in _cars)
        if (c.id == updated.id) updated else c,
    ];
    notifyListeners();
    return updated;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _cars = _cars.where((c) => c.id != id).toList(growable: false);
    notifyListeners();
  }

  Car? carById(String id) {
    for (final car in _cars) {
      if (car.id == id) return car;
    }
    return null;
  }

  List<RentalExtra> get extras => MockCars.extras;

  List<String> get cities => MockCars.villes;

  List<String> get agencies => MockCars.agences;

  List<Car> get featured =>
      _cars.where((c) => c.available).take(6).toList();

  List<Car> get recommended {
    final list = _cars.where((c) => c.available).toList()
      ..sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    return list.take(6).toList();
  }

  List<Car> get promos => _cars.where((c) => c.hasPromo).toList();

  List<Car> byCategory(CarCategory category) =>
      _cars.where((c) => c.category == category).toList();

  int countForCategory(CarCategory category) =>
      _cars.where((c) => c.category == category).length;

  List<Car> get filteredCars {
    var result = _cars.where((car) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final haystack =
            '${car.brand} ${car.model} ${car.year} ${car.city} '
                    '${car.features.join(' ')} ${car.description}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (_category != null && car.category != _category) return false;
      if (_brands.isNotEmpty && !_brands.contains(car.brand)) return false;
      if (_city != null && car.city != _city) return false;
      if (car.pricePerDay < _minPrice || car.pricePerDay > _maxPrice) {
        return false;
      }
      if (_minSeats != null && car.seats < _minSeats!) return false;
      if (_onlyAvailable) {
        final range = _searchRange;
        if (range != null) {
          if (!car.isAvailableFor(range)) return false;
        } else if (!car.available) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sort) {
      case CarSort.prixCroissant:
        result.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      case CarSort.prixDecroissant:
        result.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
      case CarSort.marque:
        result.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      case CarSort.annee:
        result.sort((a, b) => b.year.compareTo(a.year));
      case CarSort.pertinence:
        result.sort((a, b) {
          if (a.available != b.available) return a.available ? -1 : 1;
          return a.pricePerDay.compareTo(b.pricePerDay);
        });
    }
    return result;
  }

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  void setCategory(CarCategory? value) {
    _category = _category == value ? null : value;
    notifyListeners();
  }

  void toggleBrand(String brand) {
    if (!_brands.remove(brand)) _brands.add(brand);
    notifyListeners();
  }

  void setCity(String? value) {
    _city = _city == value ? null : value;
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void setMinSeats(int? value) {
    _minSeats = _minSeats == value ? null : value;
    notifyListeners();
  }

  void setOnlyAvailable(bool value) {
    _onlyAvailable = value;
    notifyListeners();
  }

  void setSort(CarSort value) {
    _sort = value;
    notifyListeners();
  }

  void setSearchRange(DateRange? range) {
    _searchRange = range;
    notifyListeners();
  }

  void resetFilters() {
    _query = '';
    _category = null;
    _brands.clear();
    _city = null;
    _minPrice = 0;
    _maxPrice = priceCeiling;
    _minSeats = null;
    _onlyAvailable = false;
    _sort = CarSort.pertinence;
    notifyListeners();
  }
}
