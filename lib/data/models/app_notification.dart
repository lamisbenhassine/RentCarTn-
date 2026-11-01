/// Notification in-app (nouvelle enchère, etc.).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.auctionId,
    this.read = false,
    this.type = AppNotificationType.auction,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? auctionId;
  final bool read;
  final AppNotificationType type;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        auctionId: auctionId,
        read: read ?? this.read,
        type: type,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'auctionId': auctionId,
        'read': read,
        'type': type.name,
      };

  factory AppNotification.fromJson(Map<String, Object?> json) =>
      AppNotification(
        id: json['id']! as String,
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.now(),
        auctionId: json['auctionId'] as String?,
        read: json['read'] as bool? ?? false,
        type: AppNotificationType.values.byName(
          (json['type'] as String?) ?? AppNotificationType.auction.name,
        ),
      );
}

enum AppNotificationType { auction, system }

extension AppNotificationTypeX on AppNotificationType {
  String get label => switch (this) {
        AppNotificationType.auction => 'Enchère',
        AppNotificationType.system => 'Système',
      };
}
