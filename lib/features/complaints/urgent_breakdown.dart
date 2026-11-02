import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/complaint.dart';
import '../../data/models/reservation.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_provider.dart';
import '../../state/car_provider.dart';
import '../../state/complaint_provider.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';
import 'complaint_actions.dart';

/// Gros bouton rouge « Panne urgente » (Mes réclamations, détail d'une
/// réservation en cours). 1ᵉʳ clic : ouvre la feuille ; 2ᵉ clic : envoie.
class UrgentBreakdownButton extends StatelessWidget {
  const UrgentBreakdownButton({super.key, this.reservationId});

  /// Réservation concernée ; sinon la location en cours est utilisée.
  final String? reservationId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: AppColors.danger,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () =>
            showUrgentBreakdownSheet(context, reservationId: reservationId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.car_crash_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.urgentButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.urgentButtonSub,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feuille de confirmation : la position est cherchée dès l'ouverture,
/// puis « Envoyer l'alerte » crée la réclamation et ouvre l'écran d'aide.
Future<void> showUrgentBreakdownSheet(
  BuildContext context, {
  String? reservationId,
}) async {
  await context.read<ReservationProvider>().load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _UrgentSheet(reservationId: reservationId),
  );
}

class _UrgentSheet extends StatefulWidget {
  const _UrgentSheet({this.reservationId});

  final String? reservationId;

  @override
  State<_UrgentSheet> createState() => _UrgentSheetState();
}

class _UrgentSheetState extends State<_UrgentSheet> {
  late final Future<DetectedLocation?> _location;
  DetectedLocation? _found;
  bool _locating = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    context.read<CarProvider>().load(); // nom de la voiture (catalogue)
    // GPS refusé / désactivé : l'alerte part quand même, sans position.
    _location = const LocationService()
        .detect()
        .then<DetectedLocation?>((d) => d)
        .catchError((Object e) {
          debugPrint('[UrgentBreakdown] Position indisponible : $e');
          return null;
        });
    _location.then((d) {
      if (mounted) {
        setState(() {
          _found = d;
          _locating = false;
        });
      }
    });
  }

  /// Réservation demandée, sinon la location en cours.
  Reservation? _reservation(ReservationProvider p) {
    final id = widget.reservationId;
    if (id != null) return p.byId(id);
    return p.activeRental;
  }

  Future<void> _send() async {
    final l = context.l10n;
    setState(() => _sending = true);
    final location = await _location; // attend la fin de la recherche GPS
    if (!mounted) return;

    final reservation = _reservation(context.read<ReservationProvider>());
    // Voiture lue dans le catalogue (table cars), pas dans la réservation.
    final car = reservation == null
        ? null
        : context.read<CarProvider>().carById(reservation.car.id);
    final created = await context.read<ComplaintProvider>().create(
      category: ComplaintCategory.panne,
      priority: ComplaintPriority.urgente,
      title: car == null ? l.urgentTitleNoCar : l.urgentTitle(car.fullName),
      description: l.urgentDescription,
      reservationId: reservation?.id,
      carId: car?.id,
      carLabel: car?.title,
      agency: reservation?.pickupCity ?? location?.nearestCity,
      latitude: location?.latitude,
      longitude: location?.longitude,
      locationAddress: location?.address,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (created == null) {
      AppSnack.error(context, l.urgentFailed);
      return;
    }
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(Routes.complaintUrgentSent(created.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final reservation = _reservation(context.watch<ReservationProvider>());

    Widget line(IconData icon, Color color, String text, {Widget? trailing}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 14, color: context.cs.onSurface),
                ),
              ),
              ?trailing,
            ],
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.car_crash_rounded, color: AppColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.urgentSheetTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.urgentSheetIntro,
              style: TextStyle(color: context.cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            reservation == null
                ? line(
                    Icons.event_busy_rounded,
                    AppColors.warning,
                    l.urgentNoReservation,
                  )
                : line(
                    Icons.directions_car_rounded,
                    AppColors.success,
                    l.urgentWithReservation(
                      context
                              .watch<CarProvider>()
                              .carById(reservation.car.id)
                              ?.fullName ??
                          '—',
                      reservation.reference,
                    ),
                  ),
            if (_locating)
              line(
                Icons.my_location_rounded,
                context.cs.primary,
                l.urgentLocating,
                trailing: const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_found != null)
              line(
                Icons.location_on_rounded,
                AppColors.success,
                l.urgentLocationOk(
                  _found!.address ??
                      '${_found!.latitude.toStringAsFixed(5)}, '
                          '${_found!.longitude.toStringAsFixed(5)}',
                ),
              )
            else
              line(
                Icons.location_off_rounded,
                AppColors.warning,
                l.urgentLocationFailed,
              ),
            const SizedBox(height: 16),
            if (!loggedIn)
              NoticeBox(
                icon: Icons.lock_outline_rounded,
                color: AppColors.warning,
                message: l.complaintLoginRequired,
              )
            else
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.campaign_rounded),
                  label: Text(
                    l.urgentSend,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => callAgency(context),
              icon: const Icon(Icons.call_rounded),
              label: Text(l.urgentCallAgency),
            ),
          ],
        ),
      ),
    );
  }
}

/// Après l'envoi : référence, appel de l'agence, conseils de sécurité.
class UrgentSentScreen extends StatelessWidget {
  const UrgentSentScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.watch<ComplaintProvider>().byId(complaintId);
    final tips = [
      (Icons.warning_amber_rounded, l.urgentTip1),
      (Icons.checkroom_rounded, l.urgentTip2),
      (Icons.change_history_rounded, l.urgentTip3),
      (Icons.shield_outlined, l.urgentTip4),
      (Icons.local_hospital_outlined, l.urgentTip5),
    ];

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        automaticallyImplyLeading: false,
        title: Text(l.urgentSentTitle),
        actions: [
          IconButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(Routes.complaints),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 560,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    size: 44,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (c != null)
                Center(
                  child: SelectableText(
                    c.reference,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: context.cs.onSurface,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                l.urgentSentMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: () => callAgency(context),
                  icon: const Icon(Icons.call_rounded),
                  label: Text(
                    '${l.urgentCallAgency} · '
                    '${ComplaintContacts.agencyPhoneDisplay}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              AppCard(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderColor: AppColors.warning.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.urgentSafetyTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: context.cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final (icon, text) in tips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 20, color: AppColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: context.cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (c != null)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.pushReplacement(Routes.complaint(c.id)),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(l.urgentSeeComplaint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
