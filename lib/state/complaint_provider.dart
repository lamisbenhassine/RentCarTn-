import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/complaint.dart';
import '../data/repositories/complaint_repository.dart';
import '../data/services/complaint_photo_store.dart';
import 'load_state.dart';

/// Notifications système (création, changement de statut, réponse de
/// l'agence). Branchées dans main.dart ; absentes dans les tests.
abstract class ComplaintAlerts {
  Future<void> created(Complaint complaint);
  Future<void> statusChanged(Complaint complaint);

  /// Réponse de l'admin sans changement de statut.
  Future<void> responded(Complaint complaint);
}

/// Réclamations de l'utilisateur connecté (front office). Le traitement
/// (prise en charge, réponse, résolution, rejet) est fait par l'admin :
/// voir AdminComplaintProvider.
///
/// Chargé automatiquement à la connexion et vidé à la déconnexion
/// (voir `_AppViewState` dans main.dart).
class ComplaintProvider extends ChangeNotifier {
  ComplaintProvider({
    ComplaintRepository? repository,
    ComplaintPhotoStore? photos,
  }) : _repository = repository ?? ComplaintRepositoryFactory.shared,
       _photos = photos ?? const ComplaintPhotoStore();

  final ComplaintRepository _repository;
  final ComplaintPhotoStore _photos;

  /// Stockage des photos (utilisé aussi par le formulaire).
  ComplaintPhotoStore get photoStore => _photos;

  List<Complaint> _complaints = [];
  LoadState _state = LoadState.initial;
  String? _errorMessage;
  String? _userId;

  /// Notifications (voir [ComplaintAlerts]).
  ComplaintAlerts? alerts;

  /// Réclamations avec une mise à jour non lue (badge), par utilisateur.
  Set<String> _unread = {};

  int get unreadCount =>
      _complaints.where((c) => _unread.contains(c.id)).length;

  bool isUnread(String id) => _unread.contains(id);

  /// Ouverture du détail : la mise à jour est lue, le badge disparaît.
  Future<void> markRead(String id) async {
    if (!_unread.remove(id)) return;
    notifyListeners();
    await _saveUnread();
  }

  List<Complaint> get complaints => _complaints;
  LoadState get state => _state;
  String? get errorMessage => _errorMessage;

  /// En attente ou en cours.
  List<Complaint> get active =>
      _complaints.where((c) => !c.status.isClosed).toList();

  /// Résolues ou rejetées.
  List<Complaint> get closed =>
      _complaints.where((c) => c.status.isClosed).toList();

  Complaint? byId(String id) {
    for (final c in _complaints) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Front office : réclamations de [userId] SEULEMENT (getByUser).
  /// `null` → liste vidée (déconnexion, compte supprimé). Le back office
  /// (toutes les réclamations, getAll) est AdminComplaintProvider.loadAll.
  Future<void> loadForUser(String? userId, {bool force = false}) async {
    if (userId == null) {
      _userId = null;
      _complaints = [];
      _unread = {};
      _state = LoadState.initial;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    if (userId == _userId && !force && _state == LoadState.success) return;

    _userId = userId;
    _state = LoadState.loading;
    notifyListeners();
    try {
      _complaints = await _repository.getByUser(userId);
      debugPrint(
        '[Complaint] getByUser(userId=$userId) → ${_complaints.length} '
        'ligne(s)',
      );
      _unread = await _loadUnread(userId);
      _state = LoadState.success;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[Complaints] Chargement impossible : $e');
      _errorMessage = 'Impossible de charger vos réclamations.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  /// Crée une réclamation « En attente » avec une référence REC-AAAA-NNNN.
  /// Retourne `null` en cas d'échec ([errorMessage] renseigné).
  Future<Complaint?> create({
    required ComplaintCategory category,
    required String title,
    required String description,
    ComplaintPriority priority = ComplaintPriority.moyenne,
    String? reservationId,
    String? auctionId,
    String? carId,
    String? carLabel,
    String? agency,
    List<String> photoPaths = const [],
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? aiSummary,
    ComplaintTone? aiTone,
  }) async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final now = DateTime.now();
      final complaint = Complaint(
        id: 'cmp-${now.microsecondsSinceEpoch}',
        reference: await _repository.nextReference(now: now),
        userId: userId,
        category: category,
        title: title.trim(),
        description: description.trim(),
        priority: priority,
        status: ComplaintStatus.enAttente,
        reservationId: reservationId,
        auctionId: auctionId,
        carId: carId,
        carLabel: carLabel,
        agency: agency,
        photoPaths: photoPaths,
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
        aiSummary: aiSummary,
        aiTone: aiTone,
        isUrgent: priority == ComplaintPriority.urgente,
        history: [
          ComplaintEvent(
            status: ComplaintStatus.enAttente,
            date: now,
            message: 'Réclamation envoyée',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      await _repository.create(complaint);
      debugPrint(
        '[Complaint] Créée ${complaint.reference} (id=${complaint.id}, '
        'userId=$userId)',
      );
      _complaints = [complaint, ..._complaints];
      _errorMessage = null;
      notifyListeners();
      _alert('created', () => alerts?.created(complaint));
      return complaint;
    } catch (e) {
      debugPrint('[Complaints] Création impossible : $e');
      _errorMessage = 'Impossible d\'envoyer la réclamation.';
      notifyListeners();
      return null;
    }
  }

  /// Enregistre une modification (date de mise à jour actualisée).
  /// [notify] : `false` quand c'est le client lui-même qui change le statut
  /// (réouverture) : pas de notification ni de badge pour sa propre action.
  Future<bool> update(Complaint complaint, {bool notify = true}) async {
    try {
      final before = byId(complaint.id);
      final saved = await _repository.update(
        complaint.copyWith(updatedAt: DateTime.now()),
      );
      _complaints = [for (final c in _complaints) c.id == saved.id ? saved : c];
      _errorMessage = null;
      if (notify && before != null && before.status != saved.status) {
        _unread.add(saved.id);
        unawaited(_saveUnread());
        _alert('statusChanged', () => alerts?.statusChanged(saved));
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Complaints] Mise à jour impossible : $e');
      _errorMessage = 'Impossible d\'enregistrer la modification.';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Satisfaction
  // ---------------------------------------------------------------------------

  /// Enregistre la note (1 à 5) et le commentaire facultatif d'une
  /// réclamation résolue. Une seule fois (voir [Complaint.canRate]).
  Future<bool> rate(String id, int rating, {String? comment}) async {
    final c = byId(id);
    if (c == null || !c.canRate || rating < 1 || rating > 5) return false;
    final text = comment?.trim() ?? '';
    return update(
      c.copyWith(rating: rating, ratingComment: text.isEmpty ? null : text),
    );
  }

  /// Note de 1 ou 2 : la réclamation repasse « En attente » (ajouté à
  /// l'historique). La note est effacée pour pouvoir noter la prochaine
  /// résolution ; elle reste tracée dans le message d'historique.
  Future<bool> reopen(String id) async {
    final c = byId(id);
    if (c == null || !c.canReopen) return false;
    final note = c.rating!;
    return update(
      c
          .withEvent(
            ComplaintStatus.enAttente,
            'Réclamation rouverte par le client (note $note/5)',
          )
          .copyWith(clearRating: true, clearClosedAt: true),
      notify: false,
    );
  }

  /// Annule (retire) une réclamation encore « En attente ». Une fois prise
  /// en charge par l'agence, elle ne peut plus être annulée.
  Future<bool> cancel(String id) async {
    final complaint = byId(id);
    if (complaint == null) return false;
    if (!complaint.canEdit) {
      _errorMessage =
          'Cette réclamation est déjà prise en charge : elle ne peut plus '
          'être annulée.';
      notifyListeners();
      return false;
    }
    try {
      await _repository.delete(id);
      // Les photos copiées dans le dossier de l'app partent avec elle
      // (un échec de nettoyage n'annule pas la suppression).
      try {
        await _photos.delete(complaint.photoPaths);
      } catch (e) {
        debugPrint('[Complaints] Photos non supprimées : $e');
      }
      _complaints = _complaints.where((c) => c.id != id).toList();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Complaints] Annulation impossible : $e');
      _errorMessage = 'Impossible d\'annuler la réclamation.';
      notifyListeners();
      return false;
    }
  }

  // --- Non lus (SharedPreferences, clé par utilisateur) ---

  static String _unreadKey(String userId) => 'complaint_unread_$userId';

  /// Action de l'admin sur la réclamation d'un AUTRE compte : badge « non
  /// lu » enregistré pour ce client (affiché à sa prochaine connexion).
  static Future<void> markUnreadFor(String userId, String complaintId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _unreadKey(userId);
      await prefs.setStringList(
        key,
        {...?prefs.getStringList(key), complaintId}.toList(),
      );
    } catch (e) {
      debugPrint('[Complaints] Non lu non enregistré pour $userId : $e');
    }
  }

  Future<Set<String>> _loadUnread(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {...?prefs.getStringList(_unreadKey(userId))};
    } catch (e) {
      debugPrint('[Complaints] Non lus illisibles : $e');
      return {};
    }
  }

  Future<void> _saveUnread() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_unreadKey(userId), _unread.toList());
    } catch (e) {
      debugPrint('[Complaints] Non lus non enregistrés : $e');
    }
  }

  /// Une notification qui échoue ne doit jamais faire échouer l'action.
  void _alert(String what, Future<void>? Function() call) {
    try {
      call()?.catchError((Object e) {
        debugPrint('[Complaints] Notification $what impossible : $e');
      });
    } catch (e) {
      debugPrint('[Complaints] Notification $what impossible : $e');
    }
  }
}
