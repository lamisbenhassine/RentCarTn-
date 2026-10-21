import '../local/app_database.dart';
import '../models/car.dart';
import '../models/reservation.dart';
import 'car_repository_prefs.dart';
import 'car_repository_sqflite.dart';

/// Contrat CRUD du parc véhicules (location).
abstract class CarRepository {
  Future<List<Car>> getAll();

  Future<Car?> byId(String id);

  Future<Car> create(Car car);

  Future<Car> update(Car car);

  Future<void> delete(String id);

  Future<void> seedIfEmpty({List<Car>? seed});

  Future<List<RentalExtra>> fetchExtras();

  Future<List<String>> fetchCities();

  Future<List<String>> fetchAgencies();
}

/// - Mobile / APK → **sqflite**
/// - Web (Chrome) → **shared_preferences**
class CarRepositoryFactory {
  static CarRepository create() {
    if (AppDatabase.instance.isSupported) {
      return SqfliteCarRepository();
    }
    return PrefsCarRepository();
  }
}

/// Aucun seed démo : le catalogue démarre vide (CRUD uniquement).
List<Car> defaultCarSeed() => const [];
