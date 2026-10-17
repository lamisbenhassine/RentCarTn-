import 'car.dart';
import 'date_range.dart';
import 'payment.dart';

enum ReservationStatus { aVenir, enCours, terminee, annulee }

extension ReservationStatusX on ReservationStatus {
  String get label => switch (this) {
    ReservationStatus.aVenir => 'À venir',
    ReservationStatus.enCours => 'En cours',
    ReservationStatus.terminee => 'Terminée',
    ReservationStatus.annulee => 'Annulée',
  };
}

/// Options payantes proposées lors de la réservation.
class RentalExtra {
  const RentalExtra({
    required this.id,
    required this.label,
    required this.pricePerDay,
    required this.icon,
    this.oneShot = false,
  });

  final String id;
  final String label;
  final double pricePerDay;
  final String icon;

  /// Facturée une seule fois au lieu de par jour.
  final bool oneShot;

  double totalFor(int days) => oneShot ? pricePerDay : pricePerDay * days;
}

class Reservation {
  Reservation({
    required this.id,
    required this.reference,
    required this.car,
    required this.range,
    required this.pickupCity,
    required this.returnCity,
    required this.pickupTime,
    required this.returnTime,
    required this.status,
    required this.createdAt,
    required this.extras,
    required this.driverName,
    required this.driverPhone,
    required this.driverEmail,
    required this.driverLicence,
    this.payment,
    this.contractNumber,
    this.notes = '',
    this.secondDriver = false,
    this.cancelReason,
  });

  final String id;
  final String reference;
  final Car car;
  final DateRange range;
  final String pickupCity;
  final String returnCity;
  final String pickupTime;
  final String returnTime;
  final ReservationStatus status;
  final DateTime createdAt;
  final List<RentalExtra> extras;
  final String driverName;
  final String driverPhone;
  final String driverEmail;
  final String driverLicence;
  final PaymentRecord? payment;
  final String? contractNumber;
  final String notes;
  final bool secondDriver;
  final String? cancelReason;

  int get days => range.days;
  double get carTotal => car.pricePerDay * days;
  double get extrasTotal =>
      extras.fold(0.0, (sum, e) => sum + e.totalFor(days));

  /// Frais de dossier simulés.
  static const double serviceFee = 15;

  double get subtotal => carTotal + extrasTotal;
  double get vat => subtotal * 0.19;
  double get total => subtotal + serviceFee + vat;

  bool get isPaid => payment?.status == PaymentStatus.reussi;

  Reservation copyWith({
    ReservationStatus? status,
    PaymentRecord? payment,
    String? contractNumber,
    String? cancelReason,
    DateRange? range,
  }) {
    return Reservation(
      id: id,
      reference: reference,
      car: car,
      range: range ?? this.range,
      pickupCity: pickupCity,
      returnCity: returnCity,
      pickupTime: pickupTime,
      returnTime: returnTime,
      status: status ?? this.status,
      createdAt: createdAt,
      extras: extras,
      driverName: driverName,
      driverPhone: driverPhone,
      driverEmail: driverEmail,
      driverLicence: driverLicence,
      payment: payment ?? this.payment,
      contractNumber: contractNumber ?? this.contractNumber,
      notes: notes,
      secondDriver: secondDriver,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }
}
