import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/models/app_notification.dart';
import '../data/models/auction.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/local_notification_service.dart';

/// Centre de notifications in-app + alerte téléphone.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    NotificationRepository? repository,
    LocalNotificationService? localService,
  })  : _repository = repository ?? NotificationRepository(),
        _local = localService ?? LocalNotificationService.instance;

  final NotificationRepository _repository;
  final LocalNotificationService _local;

  List<AppNotification> _items = [];
  bool _loaded = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  Future<void> load() async {
    if (_loaded) return;
    _items = await _repository.getAll();
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _items = await _repository.getAll();
    _loaded = true;
    notifyListeners();
  }

  /// Nouvelle enchère → notification in-app + notification téléphone.
  Future<AppNotification> notifyNewAuction(Auction auction) async {
    await load();

    final upcoming = auction.computedStatus == AuctionStatus.aVenir;
    final title = upcoming
        ? 'Nouvelle enchère planifiée'
        : 'Nouvelle enchère ouverte';

    final body = StringBuffer()
      ..writeln('${auction.title} · ${auction.city}')
      ..writeln(
        auction.isLot
            ? 'Véhicules : ${auction.vehicles.map((v) => v.fullName).join(', ')}'
            : auction.fullName,
      )
      ..writeln(
        'Prix de départ : ${Formatters.moneyShort(auction.startingPrice)}',
      )
      ..writeln(
        upcoming
            ? 'Ouverture : ${Formatters.dateTime(auction.startAt)}'
            : 'Ouverte maintenant · fin ${Formatters.dateTime(auction.endAt)}',
      )
      ..write(
        'Durée : ${_durationLabel(auction.endAt.difference(auction.startAt))}',
      );

    final notification = AppNotification(
      id: 'notif-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body.toString().trim(),
      createdAt: DateTime.now(),
      auctionId: auction.id,
      type: AppNotificationType.auction,
    );

    _items = [notification, ..._items];
    await _repository.saveAll(_items);
    notifyListeners();

    await _local.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: title,
      body:
          '${auction.title} — '
          '${upcoming ? 'ouvre le ${Formatters.dateTime(auction.startAt)}' : 'enchérissez maintenant'} · '
          '${Formatters.moneyShort(auction.startingPrice)}',
      payload: auction.id,
    );

    return notification;
  }

  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].read) return;
    _items = [
      for (var i = 0; i < _items.length; i++)
        if (i == index) _items[i].copyWith(read: true) else _items[i],
    ];
    await _repository.saveAll(_items);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (!hasUnread) return;
    _items = [for (final n in _items) n.copyWith(read: true)];
    await _repository.saveAll(_items);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items = [];
    await _repository.saveAll(_items);
    notifyListeners();
  }

  static String _durationLabel(Duration d) {
    if (d.inDays >= 1) return '${d.inDays} j';
    if (d.inHours >= 1) return '${d.inHours} h';
    return '${d.inMinutes} min';
  }
}
