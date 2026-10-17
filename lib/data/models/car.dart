import 'date_range.dart';

enum CarCategory { economique, berline, suv, luxe, electrique, utilitaire }

extension CarCategoryX on CarCategory {
  String get label => switch (this) {
    CarCategory.economique => 'Économique',
    CarCategory.berline => 'Berline',
    CarCategory.suv => 'SUV',
    CarCategory.luxe => 'Luxe',
    CarCategory.electrique => 'Électrique',
    CarCategory.utilitaire => 'Utilitaire',
  };

  String get id => name;
}

enum Transmission { manuelle, automatique }

extension TransmissionX on Transmission {
  String get label =>
      this == Transmission.manuelle ? 'Manuelle' : 'Automatique';
}

enum FuelType { essence, diesel, hybride, electrique }

extension FuelTypeX on FuelType {
  String get label => switch (this) {
    FuelType.essence => 'Essence',
    FuelType.diesel => 'Diesel',
    FuelType.hybride => 'Hybride',
    FuelType.electrique => 'Électrique',
  };
}

/// Voiture du parc de location. Les données proviennent du mock local ;
/// la structure reste alignée sur un futur DTO backend.
class Car {
  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.category,
    required this.pricePerDay,
    required this.transmission,
    required this.fuel,
    required this.seats,
    required this.doors,
    required this.luggage,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.images,
    required this.description,
    required this.features,
    required this.available,
    this.bookedRanges = const [],
    this.airConditioning = true,
    this.mileageLimitPerDay = 300,
    this.deposit = 500,
    this.promoLabel,
    this.oldPricePerDay,
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final CarCategory category;
  final double pricePerDay;
  final Transmission transmission;
  final FuelType fuel;
  final int seats;
  final int doors;
  final int luggage;
  final String city;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final String description;
  final List<String> features;

  /// Disponibilité générale (voiture en maintenance ou retirée du parc).
  final bool available;

  /// Périodes déjà réservées dans les données simulées.
  final List<DateRange> bookedRanges;

  final bool airConditioning;
  final int mileageLimitPerDay;
  final double deposit;
  final String? promoLabel;
  final double? oldPricePerDay;

  String get fullName => '$brand $model';
  String get title => '$brand $model $year';
  String get mainImage => images.isNotEmpty ? images.first : '';
  bool get hasPromo => promoLabel != null && oldPricePerDay != null;

  /// La voiture est-elle libre sur toute la période demandée ?
  bool isAvailableFor(DateRange range) {
    if (!available) return false;
    return !bookedRanges.any((booked) => booked.overlaps(range));
  }

  /// Première période bloquée qui entre en conflit (pour le message d'erreur).
  DateRange? conflictFor(DateRange range) {
    for (final booked in bookedRanges) {
      if (booked.overlaps(range)) return booked;
    }
    return null;
  }

  double totalFor(int days) => pricePerDay * days;

  Car copyWith({bool? available, List<DateRange>? bookedRanges}) {
    return Car(
      id: id,
      brand: brand,
      model: model,
      year: year,
      category: category,
      pricePerDay: pricePerDay,
      transmission: transmission,
      fuel: fuel,
      seats: seats,
      doors: doors,
      luggage: luggage,
      city: city,
      rating: rating,
      reviewCount: reviewCount,
      images: images,
      description: description,
      features: features,
      available: available ?? this.available,
      bookedRanges: bookedRanges ?? this.bookedRanges,
      airConditioning: airConditioning,
      mileageLimitPerDay: mileageLimitPerDay,
      deposit: deposit,
      promoLabel: promoLabel,
      oldPricePerDay: oldPricePerDay,
    );
  }
}
