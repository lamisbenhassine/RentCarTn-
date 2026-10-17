import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/car.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/date_range.dart';
import '../../state/cart_provider.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _changeDates(BuildContext context, CartItem item) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: item.range.start,
        end: item.range.end,
      ),
      helpText: 'Modifier la période',
      saveText: 'Valider',
      locale: const Locale('fr', 'FR'),
    );
    if (result == null || !context.mounted) return;

    final outcome = context.read<CartProvider>().updateRange(
      item.id,
      DateRange(result.start, result.end),
    );
    if (!context.mounted) return;
    outcome.ok
        ? AppSnack.success(context, outcome.message)
        : AppSnack.error(context, outcome.message);
  }

  void _remove(BuildContext context, CartItem item) {
    final cart = context.read<CartProvider>();
    cart.remove(item.id);
    AppSnack.info(context, '${item.car.fullName} retirée du panier.');
  }

  void _checkout(BuildContext context) {
    final cart = context.read<CartProvider>();
    final result = cart.validateForCheckout();
    if (!result.ok) {
      AppSnack.error(context, result.message);
      return;
    }
    context.push(Routes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Mon panier',
        subtitle: cart.isEmpty
            ? 'Aucun véhicule sélectionné'
            : '${cart.count} véhicule${cart.count > 1 ? 's' : ''} · '
                  '${Formatters.pluralDays(cart.totalDays)} au total',
        actions: [
          if (!cart.isEmpty)
            TextButton.icon(
              onPressed: () {
                cart.clear();
                AppSnack.info(context, 'Panier vidé.');
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Vider'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Votre panier est vide',
              message:
                  'Parcourez notre catalogue et ajoutez un véhicule pour '
                  'démarrer votre réservation.',
              actionLabel: 'Voir le catalogue',
              onAction: () => context.go(Routes.catalog),
            )
          : ContentContainer(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _ItemsList(
                            cart: cart,
                            onChangeDates: (i) => _changeDates(context, i),
                            onRemove: (i) => _remove(context, i),
                          ),
                        ),
                        SizedBox(
                          width: 380,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 20, 28, 20),
                            child: _SummaryCard(
                              cart: cart,
                              onCheckout: () => _checkout(context),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _ItemsList(
                      cart: cart,
                      onChangeDates: (i) => _changeDates(context, i),
                      onRemove: (i) => _remove(context, i),
                    ),
            ),
      bottomNavigationBar: cart.isEmpty || wide
          ? null
          : BottomActionBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total TTC',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.money(cart.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _checkout(context),
                      icon: const Icon(Icons.lock_rounded, size: 18),
                      label: const Text('Passer au paiement'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({
    required this.cart,
    required this.onChangeDates,
    required this.onRemove,
  });

  final CartProvider cart;
  final ValueChanged<CartItem> onChangeDates;
  final ValueChanged<CartItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        18,
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 12.0),
        24,
      ),
      children: [
        for (final item in cart.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CartItemCard(
              item: item,
              onChangeDates: () => onChangeDates(item),
              onRemove: () => onRemove(item),
            ),
          ),
        const SizedBox(height: 4),
        const NoticeBox(
          icon: Icons.verified_user_outlined,
          message:
              "Les disponibilités sont revérifiées avant le paiement. Un "
              "véhicule déjà loué sur la période sélectionnée ne peut pas "
              "être réservé.",
        ),
        if (wide) const SizedBox(height: 10),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onChangeDates,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onChangeDates;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final conflict = item.car.conflictFor(item.range);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarImage(
                url: item.car.mainImage,
                height: 78,
                width: 104,
                borderRadius: BorderRadius.circular(13),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.car.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onRemove,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Retirer',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.car.year} · ${item.car.transmission.label} · '
                      '${item.car.fuel.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${Formatters.moneyShort(item.car.pricePerDay)} / jour',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${Formatters.date(item.range.start)} → '
                        '${Formatters.date(item.range.end)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.pluralDays(item.days),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: onChangeDates,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Modifier'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${item.pickupCity} → ${item.returnCity}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item.extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final extra in item.extras)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${extra.label} · '
                      '${Formatters.moneyShort(extra.totalFor(item.days))}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (conflict != null) ...[
            const SizedBox(height: 12),
            NoticeBox(
              icon: Icons.event_busy_rounded,
              color: AppColors.danger,
              title: 'Conflit de dates',
              message:
                  'Ce véhicule est réservé du '
                  '${Formatters.date(conflict.start)} au '
                  '${Formatters.date(conflict.end)}. Modifiez la période '
                  'pour continuer.',
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sous-total de la ligne',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                Formatters.money(item.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart, required this.onCheckout});

  final CartProvider cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Récapitulatif',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          InfoRow(
            label: 'Sous-total locations',
            value: Formatters.money(cart.subtotal),
          ),
          InfoRow(
            label: 'Frais de dossier',
            value: Formatters.money(cart.serviceFees),
          ),
          InfoRow(label: 'TVA (19 %)', value: Formatters.money(cart.vat)),
          const Divider(height: 24),
          InfoRow(
            label: 'Total TTC',
            value: Formatters.money(cart.total),
            bold: true,
            valueColor: AppColors.accent,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.lock_rounded, size: 18),
              label: const Text('Passer au paiement'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(Routes.catalog),
              child: const Text('Continuer mes recherches'),
            ),
          ),
        ],
      ),
    );
  }
}
