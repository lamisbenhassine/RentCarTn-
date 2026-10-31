import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

/// Persistance locale des notifications in-app.
class NotificationRepository {
  static const _prefsKey = 'rentcar_notifications_v1';

  Future<List<AppNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = [
        for (final item in list)
          AppNotification.fromJson(Map<String, Object?>.from(item as Map)),
      ];
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<AppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = [for (final n in items) n.toJson()];
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }
}
