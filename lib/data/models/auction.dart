import 'car.dart';

enum AuctionStatus { aVenir, enCours, terminee, annulee }

extension AuctionStatusX on AuctionStatus {
  String get label => switch (this) {
        AuctionStatus.aVenir => 'À venir',
        AuctionStatus.enCours => 'En cours',
        AuctionStatus.terminee => 'Terminée',
        AuctionStatus.annulee => 'Annulée',
      };
}

enum VehicleCondition { excellent, bon, moyen, aRenover }

extension VehicleConditionX on VehicleCondition {
  String get label => switch (this) {
        VehicleCondition.excellent => 'Excellent état',
        VehicleCondition.bon => 'Bon état',
        VehicleCondition.moyen => 'État moyen',
        VehicleCondition.aRenover => 'À rénover',
      };

  String get shortLabel => switch (this) {
        VehicleCondition.excellent => 'Excellent',
        VehicleCondition.bon => 'Bon',
        VehicleCondition.moyen => 'Moyen',
        VehicleCondition.aRenover => 'À rénover',
      };
}

/// Paiement après adjudication.
enum AuctionPaymentStatus { none, awaitingPayment, paid }

extension AuctionPaymentStatusX on AuctionPaymentStatus {
  String get label => switch (this) {
        AuctionPaymentStatus.none => '—',
        AuctionPaymentStatus.awaitingPayment => 'À payer en agence',
        AuctionPaymentStatus.paid => 'Payé',
      };
}

class Bid {
  const Bid({
    required this.id,
    required this.auctionId,
    required this.bidderName,
    required this.amount,
    required this.date,
    this.bidderUserId,
    this.isCurrentUser = false,
    this.isSimulated = false,
  });

  final String id;
  final String auctionId;
  final String bidderName;
  final String? bidderUserId;
  final double amount;
  final DateTime date;
  final bool isCurrentUser;
  final bool isSimulated;

  Bid copyWith({bool? isCurrentUser}) => Bid(
        id: id,
        auctionId: auctionId,
        bidderName: bidderName,
        bidderUserId: bidderUserId,
        amount: amount,
        date: date,
        isCurrentUser: isCurrentUser ?? this.isCurrentUser,
        isSimulated: isSimulated,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'auctionId': auctionId,
        'bidderName': bidderName,
        'bidderUserId': bidderUserId,
        'amount': amount,
        'date': date.toIso8601String(),
        'isCurrentUser': isCurrentUser,
        'isSimulated': isSimulated,
      };

  factory Bid.fromJson(Map<String, Object?> json) => Bid(
        id: json['id']! as String,
        auctionId: json['auctionId']! as String,
        bidderName: json['bidderName']! as String,
        bidderUserId: json['bidderUserId'] as String?,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.tryParse((json['date'] as String?) ?? '') ??
            DateTime.now(),
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
        isSimulated: json['isSimulated'] as bool? ?? false,
      );
}

/// Véhicule du parc mis en vente aux enchères.
class Auction {
  Auction({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    required this.condition,
    required this.description,
    required this.images,
    required this.startingPrice,
    required this.minIncrement,
    required this.startAt,
    required this.endAt,
    required this.city,
    required this.fuel,
    required this.transmission,
    required this.bids,
    this.carId,
    this.hadAccident = false,
    this.extraInfo = '',
    this.doors = 4,
    this.seats = 5,
    this.airConditioning = true,
    this.status,
    this.reservePrice,
    this.cancelled = false,
    this.inspectionNotes = const [],
    this.previousOwnerLabel = 'Flotte RentCar Tunisia',
    this.paymentStatus = AuctionPaymentStatus.none,
    this.paidAt,
  });

  final String id;

  /// Lien vers le véhicule CRUD (optionnel pour anciennes ventes).
  final String? carId;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final VehicleCondition condition;

  /// Accident déclaré (oui / non).
  final bool hadAccident;

  /// Infos libres ajoutées par l'admin.
  final String extraInfo;
  final int doors;
  final int seats;
  final bool airConditioning;
  final String description;
  final List<String> images;
  final double startingPrice;
  final double minIncrement;
  final DateTime startAt;
  final DateTime endAt;
  final String city;
  final FuelType fuel;
  final Transmission transmission;
  final List<Bid> bids;
  final double? reservePrice;
  final bool cancelled;
  final List<String> inspectionNotes;
  final String previousOwnerLabel;
  final AuctionStatus? status;
  final AuctionPaymentStatus paymentStatus;
  final DateTime? paidAt;

  String get title => '$brand $model $year';
  String get fullName => '$brand $model';
  String get mainImage => images.isNotEmpty ? images.first : '';

  /// Âge du véhicule en années civiles.
  int get ageYears {
    final age = DateTime.now().year - year;
    return age < 0 ? 0 : age;
  }

  AuctionStatus get computedStatus {
    if (cancelled) return AuctionStatus.annulee;
    if (status != null) return status!;
    final now = DateTime.now();
    if (now.isBefore(startAt)) return AuctionStatus.aVenir;
    if (now.isAfter(endAt) || now.isAtSameMomentAs(endAt)) {
      return AuctionStatus.terminee;
    }
    return AuctionStatus.enCours;
  }

  bool get isOpen => computedStatus == AuctionStatus.enCours;
  bool get isEnded => computedStatus == AuctionStatus.terminee;

  Duration get remaining {
    final diff = endAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  List<Bid> get sortedBids =>
      [...bids]..sort((a, b) => b.date.compareTo(a.date));

  Bid? get highestBid {
    if (bids.isEmpty) return null;
    return bids.reduce((a, b) => a.amount >= b.amount ? a : b);
  }

  double get currentPrice => highestBid?.amount ?? startingPrice;
  int get bidCount => bids.length;
  String? get leadingBidder => highestBid?.bidderName;
  bool get hasBids => bids.isNotEmpty;

  double get minimumNextBid =>
      hasBids ? currentPrice + minIncrement : startingPrice;

  bool get reserveMet =>
      reservePrice == null || currentPrice >= reservePrice!;

  bool get currentUserIsLeading => highestBid?.isCurrentUser ?? false;

  bool get userHasBid => bids.any((b) => b.isCurrentUser);

  double? get userBestBid {
    final mine = bids.where((b) => b.isCurrentUser);
    if (mine.isEmpty) return null;
    return mine.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
  }

  Bid? get winner => isEnded ? highestBid : null;

  bool get userWon =>
      isEnded && currentUserIsLeading && userHasBid && hasBids;

  Auction copyWith({
    String? carId,
    String? brand,
    String? model,
    int? year,
    int? mileage,
    VehicleCondition? condition,
    bool? hadAccident,
    String? extraInfo,
    int? doors,
    int? seats,
    bool? airConditioning,
    String? description,
    List<String>? images,
    double? startingPrice,
    double? minIncrement,
    DateTime? startAt,
    DateTime? endAt,
    String? city,
    FuelType? fuel,
    Transmission? transmission,
    List<Bid>? bids,
    AuctionStatus? status,
    double? reservePrice,
    bool? cancelled,
    List<String>? inspectionNotes,
    String? previousOwnerLabel,
    AuctionPaymentStatus? paymentStatus,
    DateTime? paidAt,
    bool clearPaidAt = false,
    bool clearStatus = false,
  }) {
    return Auction(
      id: id,
      carId: carId ?? this.carId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      condition: condition ?? this.condition,
      hadAccident: hadAccident ?? this.hadAccident,
      extraInfo: extraInfo ?? this.extraInfo,
      doors: doors ?? this.doors,
      seats: seats ?? this.seats,
      airConditioning: airConditioning ?? this.airConditioning,
      description: description ?? this.description,
      images: images ?? this.images,
      startingPrice: startingPrice ?? this.startingPrice,
      minIncrement: minIncrement ?? this.minIncrement,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      city: city ?? this.city,
      fuel: fuel ?? this.fuel,
      transmission: transmission ?? this.transmission,
      bids: bids ?? this.bids,
      status: clearStatus ? null : (status ?? this.status),
      reservePrice: reservePrice ?? this.reservePrice,
      cancelled: cancelled ?? this.cancelled,
      inspectionNotes: inspectionNotes ?? this.inspectionNotes,
      previousOwnerLabel: previousOwnerLabel ?? this.previousOwnerLabel,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'carId': carId,
        'brand': brand,
        'model': model,
        'year': year,
        'mileage': mileage,
        'condition': condition.name,
        'hadAccident': hadAccident,
        'extraInfo': extraInfo,
        'doors': doors,
        'seats': seats,
        'airConditioning': airConditioning,
        'description': description,
        'images': images,
        'startingPrice': startingPrice,
        'minIncrement': minIncrement,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'city': city,
        'fuel': fuel.name,
        'transmission': transmission.name,
        'bids': [for (final b in bids) b.toJson()],
        'status': status?.name,
        'reservePrice': reservePrice,
        'cancelled': cancelled,
        'inspectionNotes': inspectionNotes,
        'previousOwnerLabel': previousOwnerLabel,
        'paymentStatus': paymentStatus.name,
        'paidAt': paidAt?.toIso8601String(),
      };

  factory Auction.fromJson(Map<String, Object?> json) {
    final rawBids = json['bids'] as List<dynamic>? ?? [];
    return Auction(
      id: json['id']! as String,
      carId: json['carId'] as String?,
      brand: json['brand']! as String,
      model: json['model']! as String,
      year: (json['year'] as num).toInt(),
      mileage: (json['mileage'] as num?)?.toInt() ?? 0,
      condition: VehicleCondition.values.byName(
        (json['condition'] as String?) ?? VehicleCondition.bon.name,
      ),
      hadAccident: json['hadAccident'] as bool? ?? false,
      extraInfo: (json['extraInfo'] as String?) ?? '',
      doors: (json['doors'] as num?)?.toInt() ?? 4,
      seats: (json['seats'] as num?)?.toInt() ?? 5,
      airConditioning: json['airConditioning'] as bool? ?? true,
      description: (json['description'] as String?) ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      startingPrice: (json['startingPrice'] as num).toDouble(),
      minIncrement: (json['minIncrement'] as num?)?.toDouble() ?? 500,
      startAt: DateTime.tryParse((json['startAt'] as String?) ?? '') ??
          DateTime.now(),
      endAt: DateTime.tryParse((json['endAt'] as String?) ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      city: (json['city'] as String?) ?? 'Tunis',
      fuel: FuelType.values.byName(
        (json['fuel'] as String?) ?? FuelType.essence.name,
      ),
      transmission: Transmission.values.byName(
        (json['transmission'] as String?) ?? Transmission.manuelle.name,
      ),
      bids: [
        for (final item in rawBids)
          Bid.fromJson(Map<String, Object?>.from(item as Map)),
      ],
      status: json['status'] == null
          ? null
          : AuctionStatus.values.byName(json['status']! as String),
      reservePrice: (json['reservePrice'] as num?)?.toDouble(),
      cancelled: json['cancelled'] as bool? ?? false,
      inspectionNotes: (json['inspectionNotes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      previousOwnerLabel:
          (json['previousOwnerLabel'] as String?) ?? 'Flotte RentCar Tunisia',
      paymentStatus: AuctionPaymentStatus.values.byName(
        (json['paymentStatus'] as String?) ??
            AuctionPaymentStatus.none.name,
      ),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.tryParse(json['paidAt']! as String),
    );
  }

  /// Crée une enchère à partir d'un véhicule du catalogue + infos admin.
  factory Auction.fromCar({
    required Car car,
    required String auctionId,
    required int mileage,
    required VehicleCondition condition,
    required bool hadAccident,
    required String extraInfo,
    required String description,
    required double startingPrice,
    required Duration duration,
    double minIncrement = 500,
  }) {
    final now = DateTime.now();
    return Auction(
      id: auctionId,
      carId: car.id,
      brand: car.brand,
      model: car.model,
      year: car.year,
      mileage: mileage,
      condition: condition,
      hadAccident: hadAccident,
      extraInfo: extraInfo,
      doors: car.doors,
      seats: car.seats,
      airConditioning: car.airConditioning,
      description: description.isEmpty ? car.description : description,
      images: List<String>.from(car.images),
      startingPrice: startingPrice,
      minIncrement: minIncrement,
      startAt: now,
      endAt: now.add(duration),
      city: car.city,
      fuel: car.fuel,
      transmission: car.transmission,
      bids: const [],
      paymentStatus: AuctionPaymentStatus.none,
    );
  }
}
