import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/cart_item.dart';
import '../data/models/payment.dart';
import '../data/models/reservation.dart';
import '../data/repositories/reservation_repository.dart';
import 'load_state.dart';

class ReservationProvider extends ChangeNotifier {
  ReservationProvider({ReservationRepository? repository})
    : _repository = repository ?? const ReservationRepository();

  final ReservationRepository _repository;
  final Random _random = Random();

  List<Reservation> _reservations = [];
  LoadState _state = LoadState.initial;
  String? _errorMessage;

  List<Reservation> get reservations => _reservations;
  LoadState get state => _state;
  String? get errorMessage => _errorMessage;

  List<Reservation> byStatus(ReservationStatus status) =>
      _reservations.where((r) => r.status == status).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int countByStatus(ReservationStatus status) =>
      _reservations.where((r) => r.status == status).length;

  Reservation? byId(String id) {
    for (final r in _reservations) {
      if (r.id == id) return r;
    }
    return null;
  }

  Reservation? get nextUpcoming {
    final upcoming = byStatus(ReservationStatus.aVenir);
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.range.start.compareTo(b.range.start));
    return upcoming.first;
  }

  Reservation? get activeRental {
    final active = byStatus(ReservationStatus.enCours);
    return active.isEmpty ? null : active.first;
  }

  double get totalSpent => _reservations
      .where((r) => r.isPaid)
      .fold(0.0, (sum, r) => sum + r.total);

  Future<void> load({bool force = false}) async {
    if (_state == LoadState.loading) return;
    if (_reservations.isNotEmpty && !force) return;

    _state = LoadState.loading;
    notifyListeners();
    try {
      _reservations = await _repository.fetchReservations();
      _state = LoadState.success;
    } catch (_) {
      _errorMessage = 'Impossible de charger vos réservations.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  /// Transforme les lignes du panier en réservations confirmées + contrats.
  List<Reservation> confirmFromCart({
    required List<CartItem> items,
    required String driverName,
    required String driverPhone,
    required String driverEmail,
    required String driverLicence,
    required PaymentRecord payment,
    String notes = '',
    bool secondDriver = false,
  }) {
    final created = <Reservation>[];
    final stamp = DateTime.now();

    for (final item in items) {
      final sequence = 10500 + _random.nextInt(8999);
      final reference = 'RC-${stamp.year}-$sequence';
      final reservation = Reservation(
        id: 'res-${stamp.microsecondsSinceEpoch}-${created.length}',
        reference: reference,
        car: item.car,
        range: item.range,
        pickupCity: item.pickupCity,
        returnCity: item.returnCity,
        pickupTime: item.pickupTime,
        returnTime: item.returnTime,
        status: ReservationStatus.aVenir,
        createdAt: stamp,
        extras: item.extras,
        driverName: driverName,
        driverPhone: driverPhone,
        driverEmail: driverEmail,
        driverLicence: driverLicence,
        payment: payment,
        contractNumber: 'CT-${stamp.year}-$sequence',
        notes: notes,
        secondDriver: secondDriver,
      );
      created.add(reservation);
    }

    _reservations = [...created, ..._reservations];
    notifyListeners();
    return created;
  }

  void cancel(String id, {String reason = 'Annulée par le client'}) {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final current = _reservations[index];
    _reservations[index] = current.copyWith(
      status: ReservationStatus.annulee,
      cancelReason: reason,
      payment: current.payment == null
          ? null
          : PaymentRecord(
              id: current.payment!.id,
              amount: current.payment!.amount,
              method: current.payment!.method,
              status: current.payment!.status == PaymentStatus.reussi
                  ? PaymentStatus.rembourse
                  : current.payment!.status,
              date: current.payment!.date,
              maskedCard: current.payment!.maskedCard,
            ),
    );
    notifyListeners();
  }
}
