import 'package:flutter/foundation.dart';

import '../data/models/car.dart';
import '../data/models/cart_item.dart';
import '../data/models/date_range.dart';
import '../data/models/reservation.dart';

/// Résultat d'une opération panier, pour afficher un message précis.
class CartResult {
  const CartResult.success(this.message) : ok = true;
  const CartResult.failure(this.message) : ok = false;

  final bool ok;
  final String message;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);

  /// Frais de dossier simulés, appliqués une fois par réservation.
  double get serviceFees => _items.isEmpty ? 0 : Reservation.serviceFee * _items.length;

  double get vat => (subtotal + serviceFees) * 0.19;

  double get total => subtotal + serviceFees + vat;

  int get totalDays => _items.fold(0, (sum, i) => sum + i.days);

  bool contains(String carId) => _items.any((i) => i.car.id == carId);

  CartItem? itemForCar(String carId) {
    for (final item in _items) {
      if (item.car.id == carId) return item;
    }
    return null;
  }

  CartResult add({
    required Car car,
    required DateRange range,
    required String pickupCity,
    required String returnCity,
    String pickupTime = '10:00',
    String returnTime = '10:00',
    List<RentalExtra> extras = const [],
  }) {
    if (!range.isValid) {
      return const CartResult.failure(
        'La date de retour doit suivre la date de départ.',
      );
    }
    if (!car.available) {
      return const CartResult.failure(
        "Ce véhicule n'est pas disponible à la location.",
      );
    }
    final conflict = car.conflictFor(range);
    if (conflict != null) {
      return CartResult.failure(
        'Véhicule déjà réservé du ${_fmt(conflict.start)} au '
        '${_fmt(conflict.end)}. Choisissez d\'autres dates.',
      );
    }
    // Empêche deux lignes sur le même véhicule avec des dates qui se recoupent.
    for (final item in _items) {
      if (item.car.id == car.id && item.range.overlaps(range)) {
        return const CartResult.failure(
          'Ce véhicule est déjà dans votre panier sur des dates qui se '
          'chevauchent.',
        );
      }
    }

    _items.add(
      CartItem(
        id: 'cart-${DateTime.now().microsecondsSinceEpoch}',
        car: car,
        range: range,
        pickupCity: pickupCity,
        returnCity: returnCity,
        pickupTime: pickupTime,
        returnTime: returnTime,
        extras: extras,
      ),
    );
    notifyListeners();
    return CartResult.success('${car.fullName} ajoutée au panier.');
  }

  CartResult updateRange(String itemId, DateRange range) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) {
      return const CartResult.failure('Ligne introuvable.');
    }
    if (!range.isValid) {
      return const CartResult.failure(
        'La date de retour doit suivre la date de départ.',
      );
    }

    final item = _items[index];
    final conflict = item.car.conflictFor(range);
    if (conflict != null) {
      return CartResult.failure(
        'Indisponible du ${_fmt(conflict.start)} au ${_fmt(conflict.end)}.',
      );
    }
    for (var i = 0; i < _items.length; i++) {
      if (i == index) continue;
      final other = _items[i];
      if (other.car.id == item.car.id && other.range.overlaps(range)) {
        return const CartResult.failure(
          'Ces dates chevauchent une autre ligne du panier pour ce véhicule.',
        );
      }
    }

    _items[index] = item.copyWith(range: range);
    notifyListeners();
    return const CartResult.success('Dates mises à jour.');
  }

  void updateExtras(String itemId, List<RentalExtra> extras) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(extras: extras);
    notifyListeners();
  }

  void updateLocations(String itemId, {String? pickupCity, String? returnCity}) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(
      pickupCity: pickupCity,
      returnCity: returnCity,
    );
    notifyListeners();
  }

  void remove(String itemId) {
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Contrôle global avant d'ouvrir le paiement.
  CartResult validateForCheckout() {
    if (_items.isEmpty) {
      return const CartResult.failure('Votre panier est vide.');
    }
    final today = DateTime.now();
    for (final item in _items) {
      if (!item.range.isValid) {
        return CartResult.failure(
          'Dates invalides pour ${item.car.fullName}.',
        );
      }
      if (item.range.start.isBefore(
        DateTime(today.year, today.month, today.day),
      )) {
        return CartResult.failure(
          'La prise en charge de ${item.car.fullName} est dans le passé.',
        );
      }
      final conflict = item.car.conflictFor(item.range);
      if (conflict != null) {
        return CartResult.failure(
          '${item.car.fullName} n\'est plus disponible sur ces dates.',
        );
      }
    }
    return const CartResult.success('Panier validé.');
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
