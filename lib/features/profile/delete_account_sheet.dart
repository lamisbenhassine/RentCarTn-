import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reservation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';

/// Ouvre la confirmation « Supprimer mon compte ».
Future<void> showDeleteAccountSheet(BuildContext context) async {
  // Les réservations doivent être connues pour bloquer si besoin.
  await context.read<ReservationProvider>().load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _input = TextEditingController();

  /// `null` tant qu'on ne sait pas ; `false` = compte Google (mot à taper).
  bool? _hasPassword;
  bool _obscure = true;
  String? _fieldError;
  String? _failure;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().hasLocalPassword().then((value) {
      if (mounted) setState(() => _hasPassword = value);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    setState(() {
      _fieldError = null;
      _failure = null;
    });
    if (!_formKey.currentState!.validate()) return;

    // Gardés avant l'await : après la suppression, le profil disparaît
    // (redirection), mais le navigateur racine et le routeur restent.
    final router = GoRouter.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final auth = context.read<AuthProvider>();
    final auctions = context.read<AuctionProvider>();

    final ok = await auth.deleteAccount(
      password: _hasPassword == true ? _input.text : null,
    );
    if (!mounted) return;

    if (!ok) {
      setState(() {
        if (auth.errorCode == AuthErrorCode.wrongCurrentPassword) {
          _fieldError = l.changePwdWrongCurrent;
        } else {
          _failure = l.deleteFailed;
        }
      });
      return;
    }

    auctions.setUsername('', userId: null);
    Navigator.of(context).pop(); // ferme la feuille
    router.go(Routes.login);
    if (rootContext.mounted) AppSnack.success(rootContext, l.deleteDone);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = context.watch<AuthProvider>().busy;
    final reservations = context.watch<ReservationProvider>();
    final active =
        reservations.countByStatus(ReservationStatus.enCours) +
        reservations.countByStatus(ReservationStatus.aVenir);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.deleteTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l.deleteIntro,
              style: TextStyle(
                fontSize: 13.5,
                color: context.cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _Item(Icons.person_outline_rounded, l.deleteItemProfile),
            _Item(Icons.photo_outlined, l.deleteItemPhoto),
            _Item(Icons.tune_rounded, l.deleteItemPrefs),
            _Item(Icons.history_rounded, l.deleteItemHistory),
            const SizedBox(height: 16),
            if (active > 0)
              ..._blocked(l, active)
            else if (_hasPassword == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _form(l, busy),
          ],
        ),
      ),
    );
  }

  /// Réservation en cours / à venir : suppression impossible.
  List<Widget> _blocked(AppLocalizations l, int count) => [
    NoticeBox(
      icon: Icons.event_busy_rounded,
      color: AppColors.danger,
      message: l.deleteBlocked(count),
    ),
    const SizedBox(height: 14),
    SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          context.push(Routes.reservations);
        },
        icon: const Icon(Icons.event_note_rounded),
        label: Text(l.deleteSeeReservations),
      ),
    ),
  ];

  Widget _form(AppLocalizations l, bool busy) {
    final word = l.deleteConfirmWord;
    final google = _hasPassword == false;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (google) ...[
            Text(
              l.deleteGoogleHint(word),
              style: TextStyle(
                fontSize: 13,
                color: context.cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: _input,
            obscureText: !google && _obscure,
            autocorrect: false,
            textCapitalization: google
                ? TextCapitalization.characters
                : TextCapitalization.none,
            decoration: InputDecoration(
              labelText: google ? l.deleteTypeLabel(word) : l.changePwdCurrent,
              prefixIcon: Icon(
                google ? Icons.keyboard_rounded : Icons.lock_outline_rounded,
              ),
              suffixIcon: google
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
              errorText: _fieldError,
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (google) {
                return value == word ? null : l.deleteWordMismatch(word);
              }
              return (v == null || v.isEmpty)
                  ? l.changePwdCurrentRequired
                  : null;
            },
            onChanged: (_) {
              if (_fieldError != null) setState(() => _fieldError = null);
            },
          ),
          if (_failure != null) ...[
            const SizedBox(height: 12),
            NoticeBox(
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
              message: _failure!,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : _delete,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(0, 52),
              ),
              child: busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(l.deleteConfirm),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              child: Text(l.commonCancel),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: context.cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
