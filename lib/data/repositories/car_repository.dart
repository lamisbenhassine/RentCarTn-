import '../mock/mock_cars.dart';
import '../models/car.dart';
import '../models/reservation.dart';

/// Point d'intégration backend : remplacer le corps des méthodes par des
/// appels HTTP sans toucher aux écrans ni aux providers.
class CarRepository {
  const CarRepository();

  static const Duration _latency = Duration(milliseconds: 650);

  Future<List<Car>> fetchCars() async {
    await Future<void>.delayed(_latency);
    return List<Car>.from(MockCars.cars);
  }

  Future<Car?> fetchCar(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockCars.byId(id);
  }

  Future<List<RentalExtra>> fetchExtras() async {
    return MockCars.extras;
  }

  Future<List<String>> fetchCities() async => MockCars.villes;

  Future<List<String>> fetchAgencies() async => MockCars.agences;
}
