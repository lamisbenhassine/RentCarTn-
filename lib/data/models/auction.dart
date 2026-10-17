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

class Bid {
  const Bid({
    required this.id,
    required this.auctionId,
    required this.bidderName,
    required this.amount,
    required this.date,
    this.isCurrentUser = false,
    this.isSimulated = false,
  });

  final String id;
  final String auctionId;

  /// Pseudonyme public (jamais le nom réel).
  final String bidderName;
  final double amount;
  final DateTime date;
  final bool isCurrentUser;

  /// Enchère générée par le panneau de simulation de la démo.
  final bool isSimulated;
}

/// Véhicule d'occasion du parc mis en vente aux enchères.
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
    this.status,
    this.reservePrice,
    this.cancelled = false,
    this.inspectionNotes = const [],
    this.previousOwnerLabel = 'Flotte RentCar Tunisia',
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final VehicleCondition condition;
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

  /// Statut forcé (rarement utilisé) ; sinon calculé depuis les dates.
  final AuctionStatus? status;

  String get title => '$brand $model $year';
  String get fullName => '$brand $model';
  String get mainImage => images.isNotEmpty ? images.first : '';

  AuctionStatus get computedStatus {
    if (cancelled) return AuctionStatus.annulee;
    if (status != null) return status!;
    final now = DateTime.now();
    if (now.isBefore(startAt)) return AuctionStatus.aVenir;
    if (now.isAfter(endAt)) return AuctionStatus.terminee;
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

  /// Montant minimal accepté pour la prochaine enchère.
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

  /// Gagnant une fois l'enchère close (null si aucune offre).
  Bid? get winner => isEnded ? highestBid : null;

  Auction copyWith({List<Bid>? bids, AuctionStatus? status, bool? cancelled}) {
    return Auction(
      id: id,
      brand: brand,
      model: model,
      year: year,
      mileage: mileage,
      condition: condition,
      description: description,
      images: images,
      startingPrice: startingPrice,
      minIncrement: minIncrement,
      startAt: startAt,
      endAt: endAt,
      city: city,
      fuel: fuel,
      transmission: transmission,
      bids: bids ?? this.bids,
      status: status ?? this.status,
      reservePrice: reservePrice,
      cancelled: cancelled ?? this.cancelled,
      inspectionNotes: inspectionNotes,
      previousOwnerLabel: previousOwnerLabel,
    );
  }
}
