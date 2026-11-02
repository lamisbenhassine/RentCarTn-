/// Un bannissement dans l'historique d'un compte (table ban_history).
class BanRecord {
  const BanRecord({
    required this.id,
    required this.userId,
    required this.adminId,
    required this.reason,
    required this.start,
    this.adminName,
    this.end,
    this.permanent = false,
    this.complaintId,
    this.liftedAt,
    this.liftedBy,
  });

  final String id;
  final String userId;
  final String adminId;

  /// Nom de l'admin au moment du bannissement (affichage).
  final String? adminName;
  final String reason;
  final DateTime start;

  /// Fin prévue, `null` si [permanent].
  final DateTime? end;
  final bool permanent;

  /// Réclamation à l'origine du bannissement (rejet abusif), facultatif.
  final String? complaintId;

  /// Débannissement : par un admin, ou automatique à la date de fin.
  final DateTime? liftedAt;
  final String? liftedBy;

  /// Toujours en vigueur à [now].
  bool isActive([DateTime? now]) {
    if (liftedAt != null) return false;
    if (permanent) return true;
    return end != null && end!.isAfter(now ?? DateTime.now());
  }

  BanRecord copyWith({DateTime? liftedAt, String? liftedBy}) => BanRecord(
    id: id,
    userId: userId,
    adminId: adminId,
    adminName: adminName,
    reason: reason,
    start: start,
    end: end,
    permanent: permanent,
    complaintId: complaintId,
    liftedAt: liftedAt ?? this.liftedAt,
    liftedBy: liftedBy ?? this.liftedBy,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'adminId': adminId,
    'adminName': adminName,
    'reason': reason,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'permanent': permanent,
    'complaintId': complaintId,
    'liftedAt': liftedAt?.toIso8601String(),
    'liftedBy': liftedBy,
  };

  factory BanRecord.fromJson(Map<String, Object?> json) {
    DateTime? date(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return BanRecord(
      id: '${json['id']}',
      userId: '${json['userId']}',
      adminId: '${json['adminId'] ?? ''}',
      adminName: json['adminName'] as String?,
      reason: (json['reason'] as String?) ?? '',
      start: date(json['start']) ?? DateTime.now(),
      end: date(json['end']),
      permanent: json['permanent'] == true || json['permanent'] == 1,
      complaintId: json['complaintId'] as String?,
      liftedAt: date(json['liftedAt']),
      liftedBy: json['liftedBy'] as String?,
    );
  }
}
