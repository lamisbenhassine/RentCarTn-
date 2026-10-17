import '../models/date_range.dart';
import '../models/payment.dart';
import '../models/reservation.dart';
import 'mock_cars.dart';

/// Historique de réservations simulé pour alimenter « Mes réservations ».
class MockReservations {
  MockReservations._();

  static DateTime _d(int addDays) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: addDays));
  }

  static List<Reservation> build() {
    final user = (
      name: 'Sofien Ben Amor',
      phone: '22 345 678',
      email: 'demo@rentcar.tn',
      licence: 'TN-2015-884512',
    );

    return [
      Reservation(
        id: 'res-001',
        reference: 'RC-2026-10418',
        car: MockCars.cars[3], // Hyundai Tucson
        range: DateRange(_d(6), _d(11)),
        pickupCity: 'Tunis',
        returnCity: 'Tunis',
        pickupTime: '09:00',
        returnTime: '18:00',
        status: ReservationStatus.aVenir,
        createdAt: _d(-3),
        extras: [MockCars.extras[0], MockCars.extras[2]],
        driverName: user.name,
        driverPhone: user.phone,
        driverEmail: user.email,
        driverLicence: user.licence,
        contractNumber: 'CT-2026-10418',
        payment: PaymentRecord(
          id: 'pay-001',
          amount: 1623.550,
          method: PaymentMethod.carte,
          status: PaymentStatus.reussi,
          date: _d(-3),
          maskedCard: '•••• 4821',
        ),
      ),
      Reservation(
        id: 'res-002',
        reference: 'RC-2026-10392',
        car: MockCars.cars[1], // Renault Clio
        range: DateRange(_d(-2), _d(3)),
        pickupCity: 'Sousse',
        returnCity: 'Sousse',
        pickupTime: '10:30',
        returnTime: '10:30',
        status: ReservationStatus.enCours,
        createdAt: _d(-9),
        extras: [MockCars.extras[1]],
        driverName: user.name,
        driverPhone: user.phone,
        driverEmail: user.email,
        driverLicence: user.licence,
        contractNumber: 'CT-2026-10392',
        payment: PaymentRecord(
          id: 'pay-002',
          amount: 652.750,
          method: PaymentMethod.carte,
          status: PaymentStatus.reussi,
          date: _d(-9),
          maskedCard: '•••• 4821',
        ),
      ),
      Reservation(
        id: 'res-003',
        reference: 'RC-2026-10277',
        car: MockCars.cars[11], // Skoda Octavia
        range: DateRange(_d(-28), _d(-21)),
        pickupCity: 'Hammamet',
        returnCity: 'Tunis',
        pickupTime: '14:00',
        returnTime: '12:00',
        status: ReservationStatus.terminee,
        createdAt: _d(-35),
        extras: [MockCars.extras[4]],
        driverName: user.name,
        driverPhone: user.phone,
        driverEmail: user.email,
        driverLicence: user.licence,
        contractNumber: 'CT-2026-10277',
        payment: PaymentRecord(
          id: 'pay-003',
          amount: 1434.850,
          method: PaymentMethod.agence,
          status: PaymentStatus.reussi,
          date: _d(-28),
        ),
      ),
      Reservation(
        id: 'res-004',
        reference: 'RC-2026-10198',
        car: MockCars.cars[6], // Mercedes Classe C
        range: DateRange(_d(-45), _d(-42)),
        pickupCity: 'La Marsa',
        returnCity: 'La Marsa',
        pickupTime: '08:00',
        returnTime: '20:00',
        status: ReservationStatus.annulee,
        createdAt: _d(-52),
        extras: const [],
        driverName: user.name,
        driverPhone: user.phone,
        driverEmail: user.email,
        driverLicence: user.licence,
        cancelReason: 'Annulée par le client — changement de programme',
        payment: PaymentRecord(
          id: 'pay-004',
          amount: 1514.850,
          method: PaymentMethod.carte,
          status: PaymentStatus.rembourse,
          date: _d(-52),
          maskedCard: '•••• 4821',
        ),
      ),
      
      Reservation(
        id: 'res-005',
        reference: 'RC-2026-10101',
        car: MockCars.cars[9], // Tesla Model 3
        range: DateRange(_d(-70), _d(-66)),
        pickupCity: 'Tunis',
        returnCity: 'Sfax',
        pickupTime: '11:00',
        returnTime: '17:00',
        status: ReservationStatus.terminee,
        createdAt: _d(-78),
        extras: [MockCars.extras[0], MockCars.extras[5]],
        driverName: user.name,
        driverPhone: user.phone,
        driverEmail: user.email,
        driverLicence: user.licence,
        contractNumber: 'CT-2026-10101',
        payment: PaymentRecord(
          id: 'pay-005',
          amount: 1704.350,
          method: PaymentMethod.carte,
          status: PaymentStatus.reussi,
          date: _d(-78),
          maskedCard: '•••• 1194',
        ),
      ),
    ];
  }
}
