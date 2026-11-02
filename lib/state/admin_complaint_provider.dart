import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/complaint.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/complaint_repository.dart';
import '../data/services/trust_score_service.dart';
import 'complaint_provider.dart';
import 'load_state.dart';

/// Réclamation + son auteur (nom, e-mail, score de confiance).
class AdminComplaintEntry {
  const AdminComplaintEntry({required this.complaint, this.client});

  final Complaint complaint;

  /// `null` si le compte a été supprimé entre-temps.
  final UserProfile? client;

  String get clientName {
    final name = client?.fullName.trim() ?? '';
    return name.isEmpty ? (client?.email ?? '—') : name;
  }

  AdminComplaintEntry copyWith({Complaint? complaint, UserProfile? client}) =>
      AdminComplaintEntry(
        complaint: complaint ?? this.complaint,
        client: client ?? this.client,
      );
}

/// Tableau de bord du back office. Fonction pure ([AdminComplaintStats.of]),
/// testée unitairement.
class AdminComplaintStats {
  const AdminComplaintStats({
    required this.pending,
    required this.inProgress,
    required this.resolved,
    required this.rejected,
    required this.averageProcessing,
    required this.averageRating,
    required this.ratingCount,
  });

  final int pending;
  final int inProgress;
  final int resolved;
  final int rejected;

  /// Création → résolution / rejet, sur les réclamations closes.
  final Duration? averageProcessing;

  /// Satisfaction moyenne (sur 5) des clients qui ont noté.
  final double? averageRating;
  final int ratingCount;

  static AdminComplaintStats of(Iterable<Complaint> complaints) {
    final list = complaints.toList();
    int count(ComplaintStatus s) => list.where((c) => c.status == s).length;
    final durations = [for (final c in list) ?c.processingTime];
    final ratings = [for (final c in list) ?c.rating];
    return AdminComplaintStats(
      pending: count(ComplaintStatus.enAttente),
      inProgress: count(ComplaintStatus.enCours),
      resolved: count(ComplaintStatus.resolue),
      rejected: count(ComplaintStatus.rejetee),
      averageProcessing: durations.isEmpty
          ? null
          : Duration(
              seconds:
                  durations.fold<int>(0, (s, d) => s + d.inSeconds) ~/
                  durations.length,
            ),
      averageRating: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      ratingCount: ratings.length,
    );
  }
}

/// Ordre du back office : urgentes d'abord, puis moyennes, puis basses ;
/// à priorité égale, les plus récentes d'abord.
int compareForAdmin(Complaint a, Complaint b) {
  int rank(Complaint c) => c.isUrgent || c.priority == ComplaintPriority.urgente
      ? 0
      : (c.priority == ComplaintPriority.moyenne ? 1 : 2);
  final byPriority = rank(a).compareTo(rank(b));
  return byPriority != 0 ? byPriority : b.createdAt.compareTo(a.createdAt);
}

/// Back office des réclamations (rôle admin uniquement : route protégée
/// par `needsAdmin` dans app_router.dart).
///
/// Chaque action ajoute une étape à l'historique (nom de l'admin + date),
/// marque la réclamation « non lue » pour le client et déclenche une
/// notification. L'e-mail au client est envoyé par l'écran
/// (sendComplaintMail), comme pour la création.
class AdminComplaintProvider extends ChangeNotifier {
  AdminComplaintProvider({
    ComplaintRepository? repository,
    AuthRepository? users,
    Future<void> Function(String userId, String complaintId)? markUnread,
  }) : _repository = repository ?? ComplaintRepositoryFactory.shared,
       _users = users ?? AuthRepositoryFactory.create(),
       _markUnread = markUnread ?? ComplaintProvider.markUnreadFor;

  final ComplaintRepository _repository;
  final AuthRepository _users;
  final Future<void> Function(String userId, String complaintId) _markUnread;

  /// Notifications (même service que le front office, voir main.dart).
  ComplaintAlerts? alerts;

  List<AdminComplaintEntry> _entries = [];
  LoadState _state = LoadState.initial;
  String? _errorMessage;

  LoadState get state => _state;
  String? get errorMessage => _errorMessage;

  /// Triées par priorité puis date (voir [compareForAdmin]).
  List<AdminComplaintEntry> get entries => _entries;

  AdminComplaintStats get stats =>
      AdminComplaintStats.of(_entries.map((e) => e.complaint));

  /// En attente : pastille du menu admin.
  int get pendingCount => _entries
      .where((e) => e.complaint.status == ComplaintStatus.enAttente)
      .length;

  AdminComplaintEntry? byId(String id) {
    for (final e in _entries) {
      if (e.complaint.id == id) return e;
    }
    return null;
  }

  /// Réclamations du même client.
  List<Complaint> complaintsOf(String userId) => [
    for (final e in _entries)
      if (e.complaint.userId == userId) e.complaint,
  ];

  /// Rejetées comme abusives (écran « Utilisateurs »).
  int abusiveCountOf(String userId) =>
      complaintsOf(userId)
          .where((c) => c.status == ComplaintStatus.rejetee && c.abusive)
          .length;

  int rejectedCountOf(String userId) =>
      complaintsOf(userId)
          .where((c) => c.status == ComplaintStatus.rejetee)
          .length;

  /// Back office : TOUTES les réclamations (repository.getAll(), sans
  /// filtre userId), avec le compte de chaque client.
  Future<void> loadAll({bool force = false}) async {
    if (_state.isLoading) return;
    if (_state.isSuccess && !force) return;
    _state = LoadState.loading;
    notifyListeners();
    try {
      final all = await _repository.getAll();
      final byUser = <String, int>{};
      for (final c in all) {
        byUser[c.userId] = (byUser[c.userId] ?? 0) + 1;
      }
      debugPrint(
        '[Complaint] getAll() (admin) → ${all.length} ligne(s), '
        'par userId : $byUser',
      );
      final clients = <String, UserProfile?>{};
      for (final id in all.map((c) => c.userId).toSet()) {
        clients[id] = await _users.byId(id);
      }
      _entries = [
        for (final c in all)
          AdminComplaintEntry(complaint: c, client: clients[c.userId]),
      ]..sort((a, b) => compareForAdmin(a.complaint, b.complaint));
      _state = LoadState.success;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[AdminComplaints] Chargement impossible : $e');
      _errorMessage = 'Impossible de charger les réclamations.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  /// Vide la liste (déconnexion de l'admin).
  void clear() {
    _entries = [];
    _state = LoadState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Actions (retournent la réclamation enregistrée, `null` si refusée)
  // ---------------------------------------------------------------------------

  /// En attente → En cours.
  Future<Complaint?> takeCharge(String id, {required String by}) => _apply(id, (
    c,
  ) {
    if (c.status != ComplaintStatus.enAttente) return null;
    return c
        .withEvent(ComplaintStatus.enCours, 'Prise en charge par $by', by: by)
        .copyWith(handledBy: by);
  });

  /// Réponse au client, le dossier reste En cours.
  Future<Complaint?> respond(String id, String message, {required String by}) =>
      _apply(id, (c) {
        final text = message.trim();
        if (c.status != ComplaintStatus.enCours || text.isEmpty) return null;
        return c
            .withEvent(
              ComplaintStatus.enCours,
              'Réponse de l\'agence : $text',
              by: by,
            )
            .copyWith(agencyResponse: text);
      });

  /// En cours → Résolue, avec la réponse finale.
  Future<Complaint?> resolve(String id, String message, {required String by}) =>
      _apply(id, (c) {
        final text = message.trim();
        if (c.status != ComplaintStatus.enCours || text.isEmpty) return null;
        final now = DateTime.now();
        return c
            .withEvent(
              ComplaintStatus.resolue,
              'Réclamation résolue',
              at: now,
              by: by,
            )
            .copyWith(agencyResponse: text, closedAt: now, handledBy: by);
      });

  /// En attente / En cours → Rejetée. [abusive] : -10 sur le score de
  /// confiance du client (TrustScoreService.abusiveComplaintPenalty).
  Future<Complaint?> reject(
    String id,
    String message, {
    bool abusive = false,
    required String by,
  }) async {
    final saved = await _apply(id, (c) {
      final text = message.trim();
      if (c.status.isClosed || text.isEmpty) return null;
      final now = DateTime.now();
      return c
          .withEvent(
            ComplaintStatus.rejetee,
            abusive
                ? 'Réclamation rejetée comme abusive'
                : 'Réclamation rejetée',
            at: now,
            by: by,
          )
          .copyWith(
            agencyResponse: text,
            abusive: abusive,
            closedAt: now,
            handledBy: by,
          );
    });
    if (saved != null && abusive) await _penalize(saved.userId);
    return saved;
  }

  /// Enregistre, met à jour la liste, badge client + notification.
  Future<Complaint?> _apply(
    String id,
    Complaint? Function(Complaint current) change,
  ) async {
    final entry = byId(id);
    if (entry == null) return null;
    final next = change(entry.complaint);
    if (next == null) return null;
    try {
      final saved = await _repository.update(
        next.copyWith(updatedAt: DateTime.now()),
      );
      _entries = [
        for (final e in _entries)
          e.complaint.id == id ? e.copyWith(complaint: saved) : e,
      ]..sort((a, b) => compareForAdmin(a.complaint, b.complaint));
      _errorMessage = null;
      notifyListeners();

      unawaited(_markUnread(saved.userId, saved.id));
      final statusChanged = saved.status != entry.complaint.status;
      _alert(
        () => statusChanged
            ? alerts?.statusChanged(saved)
            : alerts?.responded(saved),
      );
      return saved;
    } catch (e) {
      debugPrint('[AdminComplaints] Action impossible sur $id : $e');
      _errorMessage = 'Impossible d\'enregistrer l\'action.';
      notifyListeners();
      return null;
    }
  }

  /// Rejet abusif : score de confiance du client -10 (borné à 0). Le
  /// profil du client recalcule le même score (évènement abusiveComplaint).
  Future<void> _penalize(String userId) async {
    try {
      final client = await _users.byId(userId);
      if (client == null) return;
      final score =
          (client.trustScore - TrustScoreService.abusiveComplaintPenalty).clamp(
            TrustScoreService.minScore,
            TrustScoreService.maxScore,
          );
      final updated = await _users.updateProfile(
        client.copyWith(trustScore: score),
      );
      _entries = [
        for (final e in _entries)
          e.complaint.userId == userId ? e.copyWith(client: updated) : e,
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminComplaints] Score de confiance non modifié : $e');
    }
  }

  /// Une notification qui échoue ne fait jamais échouer l'action.
  void _alert(Future<void>? Function() call) {
    try {
      call()?.catchError((Object e) {
        debugPrint('[AdminComplaints] Notification impossible : $e');
      });
    } catch (e) {
      debugPrint('[AdminComplaints] Notification impossible : $e');
    }
  }
}
