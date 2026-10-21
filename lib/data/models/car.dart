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

/// Véhicule de location — champs métier principaux :
/// marque, places, prix, portes, clim, bagages, année, description,
/// équipements, lieu. Les autres champs restent pour compatibilité.
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
  final bool available;
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

  bool isAvailableFor(DateRange range) {
    if (!available) return false;
    return !bookedRanges.any((booked) => booked.overlaps(range));
  }

  DateRange? conflictFor(DateRange range) {
    for (final booked in bookedRanges) {
      if (booked.overlaps(range)) return booked;
    }
    return null;
  }

  double totalFor(int days) => pricePerDay * days;

  Car copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    CarCategory? category,
    double? pricePerDay,
    Transmission? transmission,
    FuelType? fuel,
    int? seats,
    int? doors,
    int? luggage,
    String? city,
    double? rating,
    int? reviewCount,
    List<String>? images,
    String? description,
    List<String>? features,
    bool? available,
    List<DateRange>? bookedRanges,
    bool? airConditioning,
    int? mileageLimitPerDay,
    double? deposit,
    String? promoLabel,
    double? oldPricePerDay,
    bool clearPromo = false,
  }) {
    return Car(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      category: category ?? this.category,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      transmission: transmission ?? this.transmission,
      fuel: fuel ?? this.fuel,
      seats: seats ?? this.seats,
      doors: doors ?? this.doors,
      luggage: luggage ?? this.luggage,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      images: images ?? this.images,
      description: description ?? this.description,
      features: features ?? this.features,
      available: available ?? this.available,
      bookedRanges: bookedRanges ?? this.bookedRanges,
      airConditioning: airConditioning ?? this.airConditioning,
      mileageLimitPerDay: mileageLimitPerDay ?? this.mileageLimitPerDay,
      deposit: deposit ?? this.deposit,
      promoLabel: clearPromo ? null : (promoLabel ?? this.promoLabel),
      oldPricePerDay: clearPromo
          ? null
          : (oldPricePerDay ?? this.oldPricePerDay),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'category': category.name,
        'pricePerDay': pricePerDay,
        'transmission': transmission.name,
        'fuel': fuel.name,
        'seats': seats,
        'doors': doors,
        'luggage': luggage,
        'city': city,
        'rating': rating,
        'reviewCount': reviewCount,
        'images': images,
        'description': description,
        'features': features,
        'available': available,
        'airConditioning': airConditioning,
        'mileageLimitPerDay': mileageLimitPerDay,
        'deposit': deposit,
        'promoLabel': promoLabel,
        'oldPricePerDay': oldPricePerDay,
        'bookedRanges': [
          for (final r in bookedRanges)
            {
              'start': r.start.toIso8601String(),
              'end': r.end.toIso8601String(),
            },
        ],
      };

  factory Car.fromJson(Map<String, Object?> json) {
    final ranges = <DateRange>[];
    final rawRanges = json['bookedRanges'] as List<dynamic>? ?? [];
    for (final item in rawRanges) {
      final map = Map<String, Object?>.from(item as Map);
      final start = DateTime.tryParse((map['start'] as String?) ?? '');
      final end = DateTime.tryParse((map['end'] as String?) ?? '');
      if (start != null && end != null) {
        ranges.add(DateRange(start, end));
      }
    }

    return Car(
      id: json['id']! as String,
      brand: json['brand']! as String,
      model: json['model']! as String,
      year: (json['year'] as num).toInt(),
      category: CarCategory.values.byName(json['category']! as String),
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      transmission: Transmission.values.byName(
        (json['transmission'] as String?) ?? Transmission.manuelle.name,
      ),
      fuel: FuelType.values.byName(
        (json['fuel'] as String?) ?? FuelType.essence.name,
      ),
      seats: (json['seats'] as num).toInt(),
      doors: (json['doors'] as num?)?.toInt() ?? 4,
      luggage: (json['luggage'] as num?)?.toInt() ?? 2,
      city: json['city']! as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      description: (json['description'] as String?) ?? '',
      features: (json['features'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      available: json['available'] as bool? ?? true,
      airConditioning: json['airConditioning'] as bool? ?? true,
      mileageLimitPerDay: (json['mileageLimitPerDay'] as num?)?.toInt() ?? 300,
      deposit: (json['deposit'] as num?)?.toDouble() ?? 500,
      promoLabel: json['promoLabel'] as String?,
      oldPricePerDay: (json['oldPricePerDay'] as num?)?.toDouble(),
      bookedRanges: ranges,
    );
  }
}
