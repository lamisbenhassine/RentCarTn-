import 'car.dart';
import 'date_range.dart';
import 'reservation.dart';

/// Ligne du panier : une voiture réservée sur une période donnée.
class CartItem {
  CartItem({
    required this.id,
    required this.car,
    required this.range,
    required this.pickupCity,
    required this.returnCity,
    this.pickupTime = '10:00',
    this.returnTime = '10:00',
    this.extras = const [],
  });

  final String id;
  final Car car;
  final DateRange range;
  final String pickupCity;
  final String returnCity;
  final String pickupTime;
  final String returnTime;
  final List<RentalExtra> extras;

  int get days => range.days;
  double get carTotal => car.pricePerDay * days;
  double get extrasTotal =>
      extras.fold(0.0, (sum, e) => sum + e.totalFor(days));
  double get total => carTotal + extrasTotal;

  CartItem copyWith({
    DateRange? range,
    String? pickupCity,
    String? returnCity,
    String? pickupTime,
    String? returnTime,
    List<RentalExtra>? extras,
  }) {
    return CartItem(
      id: id,
      car: car,
      range: range ?? this.range,
      pickupCity: pickupCity ?? this.pickupCity,
      returnCity: returnCity ?? this.returnCity,
      pickupTime: pickupTime ?? this.pickupTime,
      returnTime: returnTime ?? this.returnTime,
      extras: extras ?? this.extras,
    );
  }
}
