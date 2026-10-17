import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/mock/mock_auctions.dart';
import '../data/models/auction.dart';
import '../data/repositories/auction_repository.dart';
import 'load_state.dart';

enum AuctionSort { finBientot, prixCroissant, prixDecroissant, plusEncheres, recent }

extension AuctionSortX on AuctionSort {
  String get label => switch (this) {
    AuctionSort.finBientot => 'Fin imminente',
    AuctionSort.prixCroissant => 'Prix croissant',
    AuctionSort.prixDecroissant => 'Prix décroissant',
    AuctionSort.plusEncheres => "Plus d'enchères",
    AuctionSort.recent => 'Plus récentes',
  };
}

class BidResult {
  const BidResult.success(this.message) : ok = true;
  const BidResult.failure(this.message) : ok = false;

  final bool ok;
  final String message;
}

/// État des enchères. Toutes les offres sont locales à la session.
///
/// Limite assumée de la démo : le compte à rebours et la clôture s'appuient
/// sur l'horloge du client. Une implémentation réelle doit valider l'heure et
/// chaque offre côté serveur.
class AuctionProvider extends ChangeNotifier {
  AuctionProvider({AuctionRepository? repository})
    : _repository = repository ?? const AuctionRepository();

  final AuctionRepository _repository;
  final Random _random = Random();

  List<Auction> _auctions = [];
  LoadState _state = LoadState.initial;
  String? _errorMessage;
  Timer? _ticker;

  /// Pseudonyme public du compte courant dans les enchères.
  String _username = 'Vous';

  // --- Filtres ---
  String _query = '';
  final Set<String> _brands = {};
  VehicleCondition? _condition;
  AuctionStatus? _status;
  double _minPrice = 0;
  double _maxPrice = 100000;
  AuctionSort _sort = AuctionSort.finBientot;

  List<Auction> get auctions => _auctions;
  LoadState get state => _state;
  String? get errorMessage => _errorMessage;
  String get username => _username;

  String get query => _query;
  Set<String> get selectedBrands => _brands;
  VehicleCondition? get condition => _condition;
  AuctionStatus? get status => _status;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  AuctionSort get sort => _sort;

  List<String> get availableBrands {
    final brands = _auctions.map((a) => a.brand).toSet().toList()..sort();
    return brands;
  }

  double get priceCeiling {
    if (_auctions.isEmpty) return 100000;
    final max = _auctions
        .map((a) => a.currentPrice)
        .reduce((a, b) => a > b ? a : b);
    return (max * 1.5).ceilToDouble();
  }

  int get activeFilterCount {
    var count = 0;
    if (_brands.isNotEmpty) count++;
    if (_condition != null) count++;
    if (_status != null) count++;
    if (_minPrice > 0 || _maxPrice < priceCeiling) count++;
    return count;
  }

  void setUsername(String value) {
    if (value.isEmpty || value == _username) return;
    _username = value;
  }

  Future<void> load({bool force = false}) async {
    if (_state == LoadState.loading) return;
    if (_auctions.isNotEmpty && !force) return;

    _state = LoadState.loading;
    notifyListeners();
    try {
      _auctions = await _repository.fetchAuctions();
      _maxPrice = priceCeiling;
      _state = LoadState.success;
      _startTicker();
    } catch (_) {
      _errorMessage = 'Impossible de charger les ventes aux enchères.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  /// Rafraîchit les comptes à rebours et bascule les enchères échues.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (hasListeners) notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Auction? byId(String id) {
    for (final a in _auctions) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ------------------------------------------------------------- Catégories

  List<Auction> get liveAuctions =>
      _auctions.where((a) => a.isOpen).toList()
        ..sort((a, b) => a.endAt.compareTo(b.endAt));

  List<Auction> get endingSoon =>
      liveAuctions.where((a) => a.remaining.inHours < 24).toList();

  List<Auction> get upcoming =>
      _auctions.where((a) => a.computedStatus == AuctionStatus.aVenir).toList();

  /// Enchères auxquelles l'utilisateur participe et qui sont encore ouvertes.
  List<Auction> get participating =>
      _auctions.where((a) => a.userHasBid && a.isOpen).toList();

  List<Auction> get leading =>
      participating.where((a) => a.currentUserIsLeading).toList();

  List<Auction> get outbid =>
      participating.where((a) => !a.currentUserIsLeading).toList();

  List<Auction> get won => _auctions
      .where((a) => a.isEnded && a.userHasBid && a.currentUserIsLeading)
      .toList();

  List<Auction> get lost => _auctions
      .where((a) => a.isEnded && a.userHasBid && !a.currentUserIsLeading)
      .toList();

  List<Auction> get history =>
      _auctions.where((a) => a.userHasBid).toList()
        ..sort((a, b) => b.endAt.compareTo(a.endAt));

  /// Toutes les offres de l'utilisateur, les plus récentes d'abord.
  List<({Auction auction, Bid bid})> get myBids {
    final result = <({Auction auction, Bid bid})>[];
    for (final auction in _auctions) {
      for (final bid in auction.bids.where((b) => b.isCurrentUser)) {
        result.add((auction: auction, bid: bid));
      }
    }
    result.sort((a, b) => b.bid.date.compareTo(a.bid.date));
    return result;
  }

  List<Auction> get filteredAuctions {
    var result = _auctions.where((a) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final haystack = '${a.brand} ${a.model} ${a.year} ${a.city}'
            .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (_brands.isNotEmpty && !_brands.contains(a.brand)) return false;
      if (_condition != null && a.condition != _condition) return false;
      if (_status != null && a.computedStatus != _status) return false;
      if (a.currentPrice < _minPrice || a.currentPrice > _maxPrice) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case AuctionSort.finBientot:
        result.sort((a, b) {
          if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
          return a.endAt.compareTo(b.endAt);
        });
      case AuctionSort.prixCroissant:
        result.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
      case AuctionSort.prixDecroissant:
        result.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
      case AuctionSort.plusEncheres:
        result.sort((a, b) => b.bidCount.compareTo(a.bidCount));
      case AuctionSort.recent:
        result.sort((a, b) => b.startAt.compareTo(a.startAt));
    }
    return result;
  }

  // -------------------------------------------------------------- Mutateurs

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  void toggleBrand(String brand) {
    if (!_brands.remove(brand)) _brands.add(brand);
    notifyListeners();
  }

  void setCondition(VehicleCondition? value) {
    _condition = _condition == value ? null : value;
    notifyListeners();
  }

  void setStatus(AuctionStatus? value) {
    _status = _status == value ? null : value;
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void setSort(AuctionSort value) {
    _sort = value;
    notifyListeners();
  }

  void resetFilters() {
    _query = '';
    _brands.clear();
    _condition = null;
    _status = null;
    _minPrice = 0;
    _maxPrice = priceCeiling;
    _sort = AuctionSort.finBientot;
    notifyListeners();
  }

  // ---------------------------------------------------------------- Enchères

  /// Règles appliquées : enchère ouverte, montant > offre actuelle, respect de
  /// l'incrément minimal.
  BidResult placeBid(String auctionId, double amount) {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return const BidResult.failure('Enchère introuvable.');

    final auction = _auctions[index];

    if (auction.computedStatus == AuctionStatus.aVenir) {
      return const BidResult.failure(
        "Cette vente n'a pas encore commencé.",
      );
    }
    if (auction.computedStatus == AuctionStatus.annulee) {
      return const BidResult.failure('Cette vente a été annulée.');
    }
    if (!auction.isOpen) {
      return const BidResult.failure(
        'Cette enchère est terminée, plus aucune offre n\'est acceptée.',
      );
    }
    if (amount <= auction.currentPrice && auction.hasBids) {
      return BidResult.failure(
        "Votre offre doit dépasser l'enchère actuelle de "
        '${auction.currentPrice.toStringAsFixed(0)} TND.',
      );
    }
    if (amount < auction.minimumNextBid) {
      return BidResult.failure(
        'Offre minimale : ${auction.minimumNextBid.toStringAsFixed(0)} TND '
        '(incrément de ${auction.minIncrement.toStringAsFixed(0)} TND).',
      );
    }

    final bid = Bid(
      id: 'bid-${DateTime.now().microsecondsSinceEpoch}',
      auctionId: auctionId,
      bidderName: _username,
      amount: amount,
      date: DateTime.now(),
      isCurrentUser: true,
    );

    _auctions[index] = auction.copyWith(bids: [...auction.bids, bid]);
    notifyListeners();
    return BidResult.success(
      'Offre de ${amount.toStringAsFixed(0)} TND enregistrée. Vous êtes en tête.',
    );
  }

  /// Panneau de démonstration : génère une offre concurrente simulée.
  BidResult simulateCompetingBid(String auctionId, {double? amount}) {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return const BidResult.failure('Enchère introuvable.');

    final auction = _auctions[index];
    if (!auction.isOpen) {
      return const BidResult.failure(
        'Impossible de simuler : la vente est fermée.',
      );
    }

    final steps = 1 + _random.nextInt(3);
    final value = amount ?? auction.minimumNextBid + auction.minIncrement * (steps - 1);

    final pseudo = MockAuctions.pseudos[
      _random.nextInt(MockAuctions.pseudos.length)
    ];

    final bid = Bid(
      id: 'sim-${DateTime.now().microsecondsSinceEpoch}',
      auctionId: auctionId,
      bidderName: pseudo,
      amount: value,
      date: DateTime.now(),
      isSimulated: true,
    );

    _auctions[index] = auction.copyWith(bids: [...auction.bids, bid]);
    notifyListeners();
    return BidResult.success(
      '$pseudo a enchéri ${value.toStringAsFixed(0)} TND (offre simulée).',
    );
  }

  /// Panneau de démonstration : clôture immédiatement une vente.
  void simulateClose(String auctionId) {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    _auctions[index] = _auctions[index].copyWith(
      status: AuctionStatus.terminee,
    );
    notifyListeners();
  }

  /// Panneau de démonstration : raccourcit le compte à rebours.
  void simulateEndingSoon(String auctionId, {int seconds = 45}) {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    final a = _auctions[index];
    _auctions[index] = Auction(
      id: a.id,
      brand: a.brand,
      model: a.model,
      year: a.year,
      mileage: a.mileage,
      condition: a.condition,
      description: a.description,
      images: a.images,
      startingPrice: a.startingPrice,
      minIncrement: a.minIncrement,
      startAt: a.startAt,
      endAt: DateTime.now().add(Duration(seconds: seconds)),
      city: a.city,
      fuel: a.fuel,
      transmission: a.transmission,
      bids: a.bids,
      reservePrice: a.reservePrice,
      inspectionNotes: a.inspectionNotes,
      previousOwnerLabel: a.previousOwnerLabel,
    );
    notifyListeners();
  }

  // --------------------------------------------- Gestion de flotte (démo)

  void cancelAuction(String auctionId) {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    _auctions[index] = _auctions[index].copyWith(cancelled: true);
    notifyListeners();
  }

  void relaunch(String auctionId, {int durationDays = 7}) {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    final a = _auctions[index];
    _auctions[index] = Auction(
      id: a.id,
      brand: a.brand,
      model: a.model,
      year: a.year,
      mileage: a.mileage,
      condition: a.condition,
      description: a.description,
      images: a.images,
      startingPrice: a.startingPrice,
      minIncrement: a.minIncrement,
      startAt: DateTime.now(),
      endAt: DateTime.now().add(Duration(days: durationDays)),
      city: a.city,
      fuel: a.fuel,
      transmission: a.transmission,
      bids: const [],
      reservePrice: a.reservePrice,
      inspectionNotes: a.inspectionNotes,
      previousOwnerLabel: a.previousOwnerLabel,
    );
    notifyListeners();
  }

  void addAuction(Auction auction) {
    _auctions = [auction, ..._auctions];
    notifyListeners();
  }

  // ------------------------------------------------------------ Statistiques

  int get totalAuctions => _auctions.length;
  int get openCount => _auctions.where((a) => a.isOpen).length;
  int get endedCount => _auctions.where((a) => a.isEnded).length;
  int get totalBids => _auctions.fold(0, (sum, a) => sum + a.bidCount);

  double get estimatedRevenue => _auctions
      .where((a) => a.isEnded && a.hasBids && a.reserveMet)
      .fold(0.0, (sum, a) => sum + a.currentPrice);

  double get pipelineValue =>
      _auctions.where((a) => a.isOpen).fold(0.0, (s, a) => s + a.currentPrice);
}
