import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../data/models/payment.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _driverFormKey = GlobalKey<FormState>();
  final _cardFormKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _licence = TextEditingController();
  final _notes = TextEditingController();

  final _cardName = TextEditingController();
  final _cardNumber = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();

  int _step = 0;
  bool _secondDriver = false;
  bool _acceptConditions = false;
  PaymentMethod _method = PaymentMethod.carte;
  bool _processing = false;

  /// Permet de démontrer le chemin « paiement refusé ».
  bool _forceFailure = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _name.text = user.fullName;
      _phone.text = user.phone;
      _email.text = user.email;
      _licence.text = user.licenceNumber;
      _cardName.text = user.fullName.toUpperCase();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _licence,
      _notes,
      _cardName,
      _cardNumber,
      _cardExpiry,
      _cardCvv,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (!_driverFormKey.currentState!.validate()) return;
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      setState(() => _step = 2);
      return;
    }
    _pay();
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() => _step -= 1);
  }

  /// Seuls les quatre derniers chiffres sont conservés, en mémoire.
  String _maskedCard() {
    final digits = _cardNumber.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '•••• ••••';
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  Future<void> _pay() async {
    FocusScope.of(context).unfocus();

    if (_method == PaymentMethod.carte &&
        !_cardFormKey.currentState!.validate()) {
      return;
    }
    if (!_acceptConditions) {
      AppSnack.error(
        context,
        'Veuillez accepter les conditions de location pour continuer.',
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final validation = cart.validateForCheckout();
    if (!validation.ok) {
      AppSnack.error(context, validation.message);
      return;
    }

    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final success = !_forceFailure;
    final amount = cart.total;

    if (!success) {
      setState(() => _processing = false);
      await showDialog<void>(
        context: context,
        builder: (_) => const _PaymentFailedDialog(),
      );
      return;
    }

    final payment = PaymentRecord(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      method: _method,
      status: _method == PaymentMethod.carte
          ? PaymentStatus.reussi
          : PaymentStatus.enAttente,
      date: DateTime.now(),
      maskedCard: _method == PaymentMethod.carte ? _maskedCard() : null,
    );

    final created = context.read<ReservationProvider>().confirmFromCart(
      items: cart.items,
      driverName: _name.text.trim(),
      driverPhone: _phone.text.trim(),
      driverEmail: _email.text.trim(),
      driverLicence: _licence.text.trim(),
      payment: payment,
      notes: _notes.text.trim(),
      secondDriver: _secondDriver,
    );

    cart.clear();
    if (!mounted) return;
    setState(() => _processing = false);
    context.pushReplacement(Routes.confirmation, extra: created);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wide = Responsive.isWide(context);

    if (cart.isEmpty && !_processing) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Paiement'),
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Panier vide',
          message: 'Ajoutez un véhicule avant de passer au paiement.',
          actionLabel: 'Voir le catalogue',
          onAction: () => context.go(Routes.catalog),
        ),
      );
    }

    final steps = [
      _stepDriver(),
      _stepSummary(cart),
      _stepPayment(cart),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Finaliser la réservation',
        subtitle: 'Étape ${_step + 1} sur 3',
      ),
      body: Stack(
        children: [
          ContentContainer(
            maxWidth: 1100,
            child: Column(
              children: [
                _StepIndicator(step: _step),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 28 : 16,
                      8,
                      wide ? 28 : 16,
                      28,
                    ),
                    child: wide && _step != 2
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: steps[_step]),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 340,
                                child: _MiniSummary(cart: cart),
                              ),
                            ],
                          )
                        : steps[_step],
                  ),
                ),
              ],
            ),
          ),
          if (_processing) const _ProcessingOverlay(),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            OutlinedButton(
              onPressed: _processing ? null : _back,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(_step == 0 ? 'Annuler' : 'Retour'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _processing ? null : _next,
                child: Text(
                  _step == 2
                      ? 'Payer ${Formatters.money(cart.total)}'
                      : 'Continuer',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- Étape 1

  Widget _stepDriver() {
    return Form(
      key: _driverFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Informations du conducteur',
            subtitle:
                'Ces informations figureront sur le contrat de location.',
          ),
          AppCard(
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet du conducteur',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      Validators.required(v, champ: 'Le nom complet'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixText: '+216 ',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _licence,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de permis de conduire',
                    hintText: 'TN-2015-884512',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: Validators.licenceNumber,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Demandes particulières (facultatif)',
                    hintText:
                        'Ex. livraison à l\'aéroport, siège bébé supplémentaire…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _secondDriver,
                  onChanged: (v) => setState(() => _secondDriver = v),
                  title: const Text(
                    'Ajouter un second conducteur',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Mention ajoutée au contrat (démo)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Étape 2

  Widget _stepSummary(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Vérifiez votre réservation',
          subtitle: 'Contrôlez les véhicules, les dates et les montants.',
        ),
        for (final item in cart.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarImage(
                    url: item.car.mainImage,
                    height: 70,
                    width: 94,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.car.fullName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Formatters.date(item.range.start)} → '
                          '${Formatters.date(item.range.end)} · '
                          '${Formatters.pluralDays(item.days)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${item.pickupCity} → ${item.returnCity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (item.extras.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Options : '
                            '${item.extras.map((e) => e.label).join(', ')}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    Formatters.money(item.total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conducteur',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              InfoRow(label: 'Nom', value: _name.text, dense: true),
              InfoRow(label: 'Téléphone', value: _phone.text, dense: true),
              InfoRow(label: 'E-mail', value: _email.text, dense: true),
              InfoRow(label: 'Permis', value: _licence.text, dense: true),
              InfoRow(
                label: 'Second conducteur',
                value: _secondDriver ? 'Oui' : 'Non',
                dense: true,
              ),
              if (_notes.text.trim().isNotEmpty)
                InfoRow(label: 'Remarques', value: _notes.text, dense: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _TotalsCard(cart: cart),
      ],
    );
  }

  // ----------------------------------------------------------- Étape 3

  Widget _stepPayment(CartProvider cart) {
    final wide = Responsive.isWide(context);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Mode de paiement',
          subtitle: 'Transaction simulée — aucun débit réel.',
        ),
        for (final method in PaymentMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MethodTile(
              method: method,
              selected: _method == method,
              onTap: () => setState(() => _method = method),
            ),
          ),
        const SizedBox(height: 10),
        if (_method == PaymentMethod.carte) _cardForm(),
        if (_method == PaymentMethod.agence)
          const NoticeBox(
            icon: Icons.store_rounded,
            title: 'Paiement au comptoir',
            message:
                "Le montant sera réglé à l'agence lors de la prise en charge. "
                "Une pièce d'identité et une carte bancaire pour la caution "
                "seront demandées.",
          ),
        if (_method == PaymentMethod.virement)
          const NoticeBox(
            icon: Icons.account_balance_rounded,
            title: 'Virement bancaire',
            message:
                "Les coordonnées bancaires seraient envoyées par e-mail. La "
                "réservation reste en attente jusqu'à réception (simulation).",
          ),
        const SizedBox(height: 16),
        _SimulationPanel(
          forceFailure: _forceFailure,
          onChanged: (v) => setState(() => _forceFailure = v),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _acceptConditions,
          onChanged: (v) => setState(() => _acceptConditions = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            "J'accepte les conditions générales de location et je certifie "
            "l'exactitude des informations fournies.",
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 8),
        const NoticeBox(
          icon: Icons.shield_outlined,
          color: AppColors.success,
          title: 'Aucune donnée bancaire réelle',
          message:
              "Ce formulaire est une maquette : aucune information n'est "
              "transmise ni stockée. Seuls les 4 derniers chiffres saisis "
              "sont affichés sur le reçu de démonstration.",
        ),
      ],
    );

    if (!wide) {
      return Column(
        children: [left, const SizedBox(height: 16), _TotalsCard(cart: cart)],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: left),
        const SizedBox(width: 24),
        SizedBox(
          width: 340,
          child: Column(
            children: [
              _MiniSummary(cart: cart),
              const SizedBox(height: 14),
              _TotalsCard(cart: cart),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardForm() {
    return Form(
      key: _cardFormKey,
      child: AppCard(
        child: Column(
          children: [
            TextFormField(
              controller: _cardName,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nom sur la carte',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  Validators.required(v, champ: 'Le nom sur la carte'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cardNumber,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Numéro de carte',
                hintText: '4242 4242 4242 4242',
                prefixIcon: Icon(Icons.credit_card_rounded),
              ),
              validator: Validators.cardNumber,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cardExpiry,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Expiration',
                      hintText: 'MM/AA',
                    ),
                    validator: Validators.cardExpiry,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _cardCvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    validator: Validators.cvv,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- Composants

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  static const _labels = ['Conducteur', 'Récapitulatif', 'Paiement'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            _Dot(index: i, current: step, label: _labels[i]),
            if (i != _labels.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: i < step ? AppColors.accent : AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.index,
    required this.current,
    required this.label,
  });

  final int index;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final color = done || active ? AppColors.accent : AppColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: done || active ? color : AppColors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.6),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (method) {
    PaymentMethod.carte => Icons.credit_card_rounded,
    PaymentMethod.agence => Icons.storefront_rounded,
    PaymentMethod.virement => Icons.account_balance_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.06)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 22,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulationPanel extends StatelessWidget {
  const _SimulationPanel({required this.forceFailure, required this.onChanged});

  final bool forceFailure;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: forceFailure,
        onChanged: onChanged,
        activeThumbColor: AppColors.warning,
        title: const Text(
          'Simuler un paiement refusé',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'Panneau de démonstration : force l\'échec de la transaction.',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  const _MiniSummary({required this.cart});

  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre sélection (${cart.count})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CarImage(
                    url: item.car.mainImage,
                    height: 44,
                    width: 60,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.car.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          Formatters.pluralDays(item.days),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.moneyShort(item.total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.cart});

  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        children: [
          InfoRow(
            label: 'Sous-total',
            value: Formatters.money(cart.subtotal),
            dense: true,
          ),
          InfoRow(
            label: 'Frais de dossier',
            value: Formatters.money(cart.serviceFees),
            dense: true,
          ),
          InfoRow(
            label: 'TVA (19 %)',
            value: Formatters.money(cart.vat),
            dense: true,
          ),
          const Divider(height: 20),
          InfoRow(
            label: 'Total à payer',
            value: Formatters.money(cart.total),
            bold: true,
            valueColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navy.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                height: 44,
                width: 44,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 18),
              Text(
                'Traitement du paiement…',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Transaction simulée',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentFailedDialog extends StatelessWidget {
  const _PaymentFailedDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.credit_card_off_rounded,
          color: AppColors.danger,
          size: 28,
        ),
      ),
      title: const Text('Paiement refusé'),
      content: const Text(
        "La transaction simulée a été refusée par l'émetteur de la carte "
        "(motif : fonds insuffisants). Votre réservation n'a pas été "
        "confirmée. Vous pouvez réessayer ou choisir le paiement à l'agence.",
        style: TextStyle(fontSize: 13.5, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Formatteurs

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2, min(4, digits.length))}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
