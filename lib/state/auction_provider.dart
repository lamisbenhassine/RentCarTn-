import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/mock/mock_auctions.dart';
import '../data/models/auction.dart';
import '../data/models/car.dart';
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

/// Enchères persistées (sqflite / shared_preferences) + offres en temps réel local.
class AuctionProvider extends ChangeNotifier {
  AuctionProvider({AuctionRepository? repository})
      : _repository = repository ?? AuctionRepositoryFactory.create();

  final AuctionRepository _repository;
  final Random _random = Random();

  List<Auction> _auctions = [];
  LoadState _state = LoadState.initial;
  String? _errorMessage;
  Timer? _ticker;

  String _username = 'Vous';
  String? _userId;

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

  void setUsername(String value, {String? userId}) {
    final next = value.trim().isEmpty ? 'Vous' : value.trim();
    final changed = next != _username || userId != _userId;
    _username = next;
    _userId = userId;
    if (changed && _auctions.isNotEmpty) {
      _auctions = [
        for (final a in _auctions) _remapCurrentUser(a),
      ];
      notifyListeners();
    }
  }

  Auction _remapCurrentUser(Auction auction) {
    final bids = [
      for (final b in auction.bids)
        b.copyWith(
          isCurrentUser: (_userId != null &&
                  b.bidderUserId != null &&
                  b.bidderUserId == _userId) ||
              b.bidderName == _username,
        ),
    ];
    return auction.copyWith(bids: bids);
  }

  Future<void> load({bool force = false}) async {
    if (_state == LoadState.loading) return;
    if (_auctions.isNotEmpty && !force) return;

    _state = LoadState.loading;
    notifyListeners();
    try {
      await _repository.seedIfEmpty();
      final loaded = await _repository.getAll();
      _auctions = [
        for (final a in loaded) _finalizeIfNeeded(_remapCurrentUser(a)),
      ];
      // Persist payment status transitions after timer expiry.
      for (final a in _auctions) {
        if (a.isEnded &&
            a.hasBids &&
            a.paymentStatus == AuctionPaymentStatus.none) {
          await _persist(
            a.copyWith(paymentStatus: AuctionPaymentStatus.awaitingPayment),
          );
        }
      }
      _auctions = await _repository.getAll().then(
            (list) => [for (final a in list) _remapCurrentUser(a)],
          );
      _maxPrice = priceCeiling;
      _state = LoadState.success;
      _startTicker();
    } catch (_) {
      _errorMessage = 'Impossible de charger les ventes aux enchères.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Auction _finalizeIfNeeded(Auction auction) {
    if (!auction.isEnded) return auction;
    if (auction.hasBids &&
        auction.paymentStatus == AuctionPaymentStatus.none) {
      return auction.copyWith(
        paymentStatus: AuctionPaymentStatus.awaitingPayment,
      );
    }
    return auction;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      var changed = false;
      for (var i = 0; i < _auctions.length; i++) {
        final a = _auctions[i];
        if (a.cancelled || a.status == AuctionStatus.terminee) continue;
        if (DateTime.now().isAfter(a.endAt) &&
            a.paymentStatus == AuctionPaymentStatus.none &&
            a.hasBids) {
          final updated = a.copyWith(
            status: AuctionStatus.terminee,
            paymentStatus: AuctionPaymentStatus.awaitingPayment,
          );
          _auctions[i] = updated;
          unawaited(_repository.update(updated));
          changed = true;
        }
      }
      if (hasListeners) notifyListeners();
      if (changed) {
        // keep listeners updated after persist
      }
    });
  }

  Future<void> _persist(Auction auction) async {
    final saved = await _repository.update(auction);
    final index = _auctions.indexWhere((a) => a.id == saved.id);
    if (index != -1) {
      _auctions[index] = _remapCurrentUser(saved);
    }
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

  List<Auction> get liveAuctions =>
      _auctions.where((a) => a.isOpen).toList()
        ..sort((a, b) => a.endAt.compareTo(b.endAt));

  List<Auction> get endingSoon =>
      liveAuctions.where((a) => a.remaining.inHours < 24).toList();

  List<Auction> get upcoming =>
      _auctions.where((a) => a.computedStatus == AuctionStatus.aVenir).toList();

  List<Auction> get participating =>
      _auctions.where((a) => a.userHasBid && a.isOpen).toList();

  List<Auction> get leading =>
      participating.where((a) => a.currentUserIsLeading).toList();

  List<Auction> get outbid =>
      participating.where((a) => !a.currentUserIsLeading).toList();

  List<Auction> get won =>
      _auctions.where((a) => a.userWon).toList();

  List<Auction> get lost => _auctions
      .where((a) => a.isEnded && a.userHasBid && !a.currentUserIsLeading)
      .toList();

  List<Auction> get awaitingPayment => _auctions
      .where(
        (a) =>
            a.userWon &&
            a.paymentStatus == AuctionPaymentStatus.awaitingPayment,
      )
      .toList();

  List<Auction> get history =>
      _auctions.where((a) => a.userHasBid).toList()
        ..sort((a, b) => b.endAt.compareTo(a.endAt));

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

  /// Véhicules déjà mis en enchère (ouverts / à venir) — pour éviter les doublons.
  Set<String> get carIdsInActiveAuction => {
        for (final a in _auctions)
          if (a.carId != null &&
              !a.cancelled &&
              (a.isOpen || a.computedStatus == AuctionStatus.aVenir))
            a.carId!,
      };

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

  Future<BidResult> placeBid(String auctionId, double amount) async {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return const BidResult.failure('Enchère introuvable.');

    final auction = _auctions[index];

    if (auction.computedStatus == AuctionStatus.aVenir) {
      return const BidResult.failure("Cette vente n'a pas encore commencé.");
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
        '(pas de ${auction.minIncrement.toStringAsFixed(0)} TND).',
      );
    }

    final bid = Bid(
      id: 'bid-${DateTime.now().microsecondsSinceEpoch}',
      auctionId: auctionId,
      bidderName: _username,
      bidderUserId: _userId,
      amount: amount,
      date: DateTime.now(),
      isCurrentUser: true,
    );

    final updated = auction.copyWith(bids: [...auction.bids, bid]);
    try {
      await _persist(updated);
      notifyListeners();
      return BidResult.success(
        'Offre de ${amount.toStringAsFixed(0)} TND enregistrée. '
        'Vous êtes en tête.',
      );
    } catch (_) {
      return const BidResult.failure('Enregistrement de l\'offre impossible.');
    }
  }

  /// Remonter de +500 TND (ou minIncrement).
  Future<BidResult> raiseByIncrement(String auctionId) async {
    final auction = byId(auctionId);
    if (auction == null) {
      return const BidResult.failure('Enchère introuvable.');
    }
    return placeBid(auctionId, auction.minimumNextBid);
  }

  Future<BidResult> simulateCompetingBid(
    String auctionId, {
    double? amount,
  }) async {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return const BidResult.failure('Enchère introuvable.');

    final auction = _auctions[index];
    if (!auction.isOpen) {
      return const BidResult.failure(
        'Impossible de simuler : la vente est fermée.',
      );
    }

    final steps = 1 + _random.nextInt(3);
    final value =
        amount ?? auction.minimumNextBid + auction.minIncrement * (steps - 1);
    final pseudo =
        MockAuctions.pseudos[_random.nextInt(MockAuctions.pseudos.length)];

    final bid = Bid(
      id: 'sim-${DateTime.now().microsecondsSinceEpoch}',
      auctionId: auctionId,
      bidderName: pseudo,
      amount: value,
      date: DateTime.now(),
      isSimulated: true,
    );

    final updated = auction.copyWith(bids: [...auction.bids, bid]);
    await _persist(updated);
    notifyListeners();
    return BidResult.success(
      '$pseudo a enchéri ${value.toStringAsFixed(0)} TND (offre simulée).',
    );
  }

  Future<void> simulateClose(String auctionId) async {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    final a = _auctions[index];
    final updated = a.copyWith(
      status: AuctionStatus.terminee,
      endAt: DateTime.now(),
      paymentStatus: a.hasBids
          ? AuctionPaymentStatus.awaitingPayment
          : AuctionPaymentStatus.none,
    );
    await _persist(updated);
    notifyListeners();
  }

  Future<void> simulateEndingSoon(String auctionId, {int seconds = 45}) async {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    final a = _auctions[index];
    final updated = a.copyWith(
      endAt: DateTime.now().add(Duration(seconds: seconds)),
      clearStatus: true,
    );
    await _persist(updated);
    notifyListeners();
  }

  Future<void> cancelAuction(String auctionId) async {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    final updated = _auctions[index].copyWith(cancelled: true);
    await _persist(updated);
    notifyListeners();
  }

  Future<void> relaunch(String auctionId, {Duration? duration}) async {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return;
    final a = _auctions[index];
    final now = DateTime.now();
    final updated = a.copyWith(
      startAt: now,
      endAt: now.add(duration ?? const Duration(hours: 1)),
      bids: const [],
      clearStatus: true,
      cancelled: false,
      paymentStatus: AuctionPaymentStatus.none,
      clearPaidAt: true,
    );
    await _persist(updated);
    notifyListeners();
  }

  Future<Auction> createFromCar({
    required Car car,
    required int mileage,
    required VehicleCondition condition,
    required bool hadAccident,
    required String extraInfo,
    required String description,
    required double startingPrice,
    required Duration duration,
  }) async {
    final auction = Auction.fromCar(
      car: car,
      auctionId: 'auc-${DateTime.now().millisecondsSinceEpoch}',
      mileage: mileage,
      condition: condition,
      hadAccident: hadAccident,
      extraInfo: extraInfo,
      description: description,
      startingPrice: startingPrice,
      duration: duration,
      minIncrement: 500,
    );
    final created = await _repository.create(auction);
    _auctions = [created, ..._auctions];
    notifyListeners();
    return created;
  }

  Future<void> addAuction(Auction auction) async {
    final created = await _repository.create(auction);
    _auctions = [created, ..._auctions];
    notifyListeners();
  }

  /// Gagnant paie en agence → reçu « Payé ».
  Future<bool> markPaid(String auctionId) async {
    final index = _auctions.indexWhere((a) => a.id == auctionId);
    if (index == -1) return false;
    final a = _auctions[index];
    if (!a.userWon) return false;
    final updated = a.copyWith(
      paymentStatus: AuctionPaymentStatus.paid,
      paidAt: DateTime.now(),
    );
    await _persist(updated);
    notifyListeners();
    return true;
  }

  int get totalAuctions => _auctions.length;
  int get openCount => _auctions.where((a) => a.isOpen).length;
  int get endedCount => _auctions.where((a) => a.isEnded).length;
  int get totalBids => _auctions.fold(0, (sum, a) => sum + a.bidCount);

  double get estimatedRevenue => _auctions
      .where(
        (a) =>
            a.isEnded &&
            a.hasBids &&
            a.paymentStatus == AuctionPaymentStatus.paid,
      )
      .fold(0.0, (sum, a) => sum + a.currentPrice);

  double get pipelineValue =>
      _auctions.where((a) => a.isOpen).fold(0.0, (s, a) => s + a.currentPrice);
}
