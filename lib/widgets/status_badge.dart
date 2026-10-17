import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/auction.dart';
import '../data/models/payment.dart';
import '../data/models/reservation.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
    this.dense = false,
    this.filled = false,
  });

  /// Badge « Disponible » / « Indisponible » du catalogue.
  factory StatusBadge.availability(bool available, {bool dense = false}) {
    return StatusBadge(
      label: available ? 'Disponible' : 'Indisponible',
      color: available ? AppColors.success : AppColors.danger,
      background: available ? AppColors.successSoft : AppColors.dangerSoft,
      icon: available
          ? Icons.check_circle_rounded
          : Icons.do_not_disturb_on_rounded,
      dense: dense,
    );
  }

  factory StatusBadge.reservation(ReservationStatus status) {
    final (color, bg, icon) = switch (status) {
      ReservationStatus.aVenir => (
        AppColors.info,
        AppColors.infoSoft,
        Icons.event_available_rounded,
      ),
      ReservationStatus.enCours => (
        AppColors.success,
        AppColors.successSoft,
        Icons.directions_car_filled_rounded,
      ),
      ReservationStatus.terminee => (
        AppColors.textSecondary,
        const Color(0xFFEEF1F6),
        Icons.task_alt_rounded,
      ),
      ReservationStatus.annulee => (
        AppColors.danger,
        AppColors.dangerSoft,
        Icons.cancel_rounded,
      ),
    };
    return StatusBadge(
      label: status.label,
      color: color,
      background: bg,
      icon: icon,
    );
  }

  factory StatusBadge.payment(PaymentStatus status) {
    final (color, bg, icon) = switch (status) {
      PaymentStatus.reussi => (
        AppColors.success,
        AppColors.successSoft,
        Icons.verified_rounded,
      ),
      PaymentStatus.enAttente => (
        AppColors.warning,
        AppColors.warningSoft,
        Icons.schedule_rounded,
      ),
      PaymentStatus.echoue => (
        AppColors.danger,
        AppColors.dangerSoft,
        Icons.error_rounded,
      ),
      PaymentStatus.rembourse => (
        AppColors.info,
        AppColors.infoSoft,
        Icons.undo_rounded,
      ),
    };
    return StatusBadge(
      label: status.label,
      color: color,
      background: bg,
      icon: icon,
      dense: true,
    );
  }

  factory StatusBadge.auction(AuctionStatus status) {
    final (color, bg, icon) = switch (status) {
      AuctionStatus.enCours => (
        AppColors.success,
        AppColors.successSoft,
        Icons.gavel_rounded,
      ),
      AuctionStatus.aVenir => (
        AppColors.info,
        AppColors.infoSoft,
        Icons.schedule_rounded,
      ),
      AuctionStatus.terminee => (
        AppColors.textSecondary,
        const Color(0xFFEEF1F6),
        Icons.flag_rounded,
      ),
      AuctionStatus.annulee => (
        AppColors.danger,
        AppColors.dangerSoft,
        Icons.block_rounded,
      ),
    };
    return StatusBadge(
      label: status.label,
      color: color,
      background: bg,
      icon: icon,
    );
  }

  factory StatusBadge.condition(VehicleCondition condition) {
    final color = switch (condition) {
      VehicleCondition.excellent => AppColors.success,
      VehicleCondition.bon => AppColors.info,
      VehicleCondition.moyen => AppColors.warning,
      VehicleCondition.aRenover => AppColors.danger,
    };
    return StatusBadge(
      label: condition.shortLabel,
      color: color,
      background: color.withValues(alpha: 0.12),
      icon: Icons.build_circle_rounded,
      dense: true,
    );
  }

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool dense;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: filled ? color : (background ?? color.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
