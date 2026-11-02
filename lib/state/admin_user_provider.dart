import 'package:flutter/foundation.dart';

import '../data/models/ban_record.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/ban_service.dart';
import 'load_state.dart';

/// Résultat d'un bannissement / débannissement : compte à jour + e-mail
/// envoyé en arrière-plan (`true` si parti).
typedef BanOutcome = ({UserProfile user, Future<bool> mail});

/// Back office « Utilisateurs » (admin uniquement) : liste des comptes,
/// bannissement, débannissement, historique.
class AdminUserProvider extends ChangeNotifier {
  AdminUserProvider({AuthRepository? repository, BanService? bans})
    : _repository = repository ?? AuthRepositoryFactory.create(),
      _bansOverride = bans;

  final AuthRepository _repository;
  final BanService? _bansOverride;
  late final BanService _bans =
      _bansOverride ?? BanService(repository: _repository);

  List<UserProfile> _users = [];
  LoadState _state = LoadState.initial;
  String? _errorMessage;

  List<UserProfile> get users => _users;
  LoadState get state => _state;
  String? get errorMessage => _errorMessage;

  int get bannedCount => _users.where((u) => u.isBanned).length;

  UserProfile? byId(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Tous les comptes ; les bannissements échus sont levés au passage
  /// (réactivation automatique visible tout de suite par l'admin).
  Future<void> load({bool force = false}) async {
    if (_state.isLoading) return;
    if (_state.isSuccess && !force) return;
    _state = LoadState.loading;
    notifyListeners();
    try {
      final all = await _repository.getAllUsers();
      _users = [for (final u in all) await _bans.refresh(u)];
      _state = LoadState.success;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[AdminUsers] Chargement impossible : $e');
      _errorMessage = 'Impossible de charger les utilisateurs.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  void clear() {
    _users = [];
    _state = LoadState.initial;
    notifyListeners();
  }

  /// Lance [BanException] si la règle refuse (admin, soi-même, date…).
  Future<BanOutcome> ban({
    required String userId,
    required UserProfile admin,
    required String reason,
    Duration? duration,
    DateTime? until,
    bool permanent = false,
    String? complaintId,
  }) async {
    final user = await _bans.banUser(
      userId: userId,
      admin: admin,
      reason: reason,
      duration: duration,
      until: until,
      permanent: permanent,
      complaintId: complaintId,
    );
    _replace(user);
    return (user: user, mail: _bans.sendBanMail(user));
  }

  Future<BanOutcome> unban(String userId, {required UserProfile admin}) async {
    final user = await _bans.unbanUser(userId, admin: admin);
    _replace(user);
    return (user: user, mail: _bans.sendUnbanMail(user));
  }

  Future<List<BanRecord>> history(String userId) => _bans.getBanHistory(userId);

  /// Recharge un compte (ex. fin de bannissement atteinte à l'écran).
  Future<void> refreshUser(String userId) async {
    final user = await _repository.byId(userId);
    if (user != null) _replace(await _bans.refresh(user));
  }

  void _replace(UserProfile user) {
    final exists = _users.any((u) => u.id == user.id);
    _users = exists
        ? [for (final u in _users) u.id == user.id ? user : u]
        : [..._users, user];
    notifyListeners();
  }
}
