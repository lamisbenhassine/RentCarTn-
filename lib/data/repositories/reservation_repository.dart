import '../mock/mock_reservations.dart';
import '../models/reservation.dart';

/// Point d'intégration backend pour les réservations et contrats.
class ReservationRepository {
  const ReservationRepository();

  Future<List<Reservation>> fetchReservations() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return MockReservations.build();
  }
}
