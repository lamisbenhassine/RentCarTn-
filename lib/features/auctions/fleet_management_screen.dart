import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_images.dart';
import '../../data/models/auction.dart';
import '../../data/models/car.dart';
import '../../state/auction_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';

/// Écran de gestion des ventes de flotte — démonstration frontend.
/// Permet de suivre, relancer, annuler et créer des ventes simulées.
class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().load();
    });
  }

  Future<void> _createAuction() async {
    final created = await showModalBottomSheet<Auction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NewAuctionSheet(),
    );
    if (created == null || !mounted) return;
    context.read<AuctionProvider>().addAuction(created);
    AppSnack.success(context, 'Vente « ${created.title} » publiée (démo).');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Gestion des ventes de flotte',
        subtitle: 'Tableau de bord de démonstration',
        actions: [
          IconButton(
            tooltip: 'Nouvelle vente',
            onPressed: _createAuction,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: Responsive.isMobile(context)
          ? FloatingActionButton.extended(
              onPressed: _createAuction,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Mettre en vente'),
            )
          : null,
      body: provider.state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ContentContainer(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Responsive.value(
                    context,
                    mobile: 16.0,
                    tablet: 24.0,
                    desktop: 32.0,
                  ),
                  16,
                  Responsive.value(
                    context,
                    mobile: 16.0,
                    tablet: 24.0,
                    desktop: 32.0,
                  ),
                  90,
                ),
                children: [
                  const NoticeBox(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Espace gestionnaire (démo)',
                    message:
                        "Cet écran illustre le pilotage des ventes de "
                        "véhicules sortis du parc. Les actions modifient "
                        "uniquement l'état local de la session.",
                  ),
                  const SizedBox(height: 16),
                  _KpiGrid(provider: provider),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Ventes en cours',
                    subtitle:
                        '${provider.liveAuctions.length} véhicule'
                        '${provider.liveAuctions.length > 1 ? 's' : ''} '
                        'actuellement aux enchères',
                  ),
                  if (provider.liveAuctions.isEmpty)
                    const AppCard(
                      child: EmptyState(
                        compact: true,
                        icon: Icons.gavel_rounded,
                        title: 'Aucune vente active',
                        message:
                            'Publiez une nouvelle vente pour alimenter la '
                            'place de marché.',
                      ),
                    )
                  else
                    for (final auction in provider.liveAuctions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FleetRow(auction: auction),
                      ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: 'Ventes clôturées',
                    subtitle: 'Résultats et relances possibles',
                  ),
                  for (final auction in provider.auctions.where(
                    (a) => a.isEnded,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FleetRow(auction: auction),
                    ),
                  if (provider.upcoming.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: 'Ventes programmées',
                      subtitle: 'Ouverture planifiée',
                    ),
                    for (final auction in provider.upcoming)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FleetRow(auction: auction),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.provider});

  final AuctionProvider provider;

  @override
  Widget build(BuildContext context) {
    final kpis = <(IconData, String, String, Color)>[
      (
        Icons.directions_car_rounded,
        '${provider.totalAuctions}',
        'Véhicules en portefeuille',
        AppColors.accent,
      ),
      (
        Icons.sensors_rounded,
        '${provider.openCount}',
        'Ventes actives',
        AppColors.success,
      ),
      (
        Icons.gavel_rounded,
        '${provider.totalBids}',
        'Offres reçues',
        AppColors.gold,
      ),
      (
        Icons.payments_rounded,
        Formatters.moneyShort(provider.estimatedRevenue),
        'Produit des ventes conclues',
        AppColors.navy,
      ),
      (
        Icons.trending_up_rounded,
        Formatters.moneyShort(provider.pipelineValue),
        'Valeur en cours de négociation',
        AppColors.info,
      ),
      (
        Icons.flag_rounded,
        '${provider.endedCount}',
        'Ventes clôturées',
        AppColors.textSecondary,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.value(context, mobile: 2, tablet: 3),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: Responsive.value(
        context,
        mobile: 1.5,
        tablet: 1.9,
        desktop: 2.2,
      ),
      children: [
        for (final (icon, value, label, color) in kpis)
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FleetRow extends StatelessWidget {
  const _FleetRow({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AuctionProvider>();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarImage(
                url: auction.mainImage,
                height: 66,
                width: 90,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.mileage(auction.mileage)} · '
                      '${auction.condition.shortLabel} · ${auction.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge.auction(auction.computedStatus),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.moneyShort(auction.currentPrice),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    '${auction.bidCount} offre'
                    '${auction.bidCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push(
                  auction.isEnded
                      ? Routes.auctionResult(auction.id)
                      : Routes.auction(auction.id),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Consulter'),
              ),
              if (auction.isOpen)
                OutlinedButton.icon(
                  onPressed: () {
                    provider.cancelAuction(auction.id);
                    AppSnack.info(context, 'Vente annulée (simulation).');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('Annuler'),
                ),
              if (!auction.isOpen)
                ElevatedButton.icon(
                  onPressed: () {
                    provider.relaunch(auction.id);
                    AppSnack.success(
                      context,
                      'Vente relancée pour 7 jours (simulation).',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: AppColors.navy,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Relancer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formulaire de mise en vente d'un véhicule retiré du parc.
class _NewAuctionSheet extends StatefulWidget {
  const _NewAuctionSheet();

  @override
  State<_NewAuctionSheet> createState() => _NewAuctionSheetState();
}

class _NewAuctionSheetState extends State<_NewAuctionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: '2018');
  final _mileage = TextEditingController(text: '150000');
  final _startPrice = TextEditingController(text: '20000');
  final _increment = TextEditingController(text: '500');
  final _description = TextEditingController();

  VehicleCondition _condition = VehicleCondition.bon;
  String _city = 'Tunis';
  int _durationDays = 7;

  @override
  void dispose() {
    for (final c in [
      _brand,
      _model,
      _year,
      _mileage,
      _startPrice,
      _increment,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final auction = Auction(
      id: 'auc-${now.millisecondsSinceEpoch}',
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      year: int.parse(_year.text),
      mileage: int.parse(_mileage.text),
      condition: _condition,
      description: _description.text.trim().isEmpty
          ? 'Véhicule issu de la flotte RentCar Tunisia, mis en vente après '
                'sa période de location.'
          : _description.text.trim(),
      images: [Img.sedanBlack, Img.driving],
      startingPrice: double.parse(_startPrice.text),
      minIncrement: double.parse(_increment.text),
      startAt: now,
      endAt: now.add(Duration(days: _durationDays)),
      city: _city,
      fuel: FuelType.diesel,
      transmission: Transmission.manuelle,
      bids: const [],
      inspectionNotes: const ['Fiche créée depuis la démo de gestion'],
    );

    Navigator.of(context).pop(auction);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mettre un véhicule en vente',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brand,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Marque',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obligatoire'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _model,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Modèle',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obligatoire'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Année',
                          ),
                          validator: _validYear,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _mileage,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Kilométrage',
                            suffixText: 'km',
                          ),
                          validator: _validInt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startPrice,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix de départ',
                            suffixText: 'TND',
                          ),
                          validator: _validInt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _increment,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Incrément',
                            suffixText: 'TND',
                          ),
                          validator: _validInt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<VehicleCondition>(
                    initialValue: _condition,
                    decoration: const InputDecoration(
                      labelText: 'État du véhicule',
                    ),
                    items: [
                      for (final c in VehicleCondition.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (v) =>
                        setState(() => _condition = v ?? _condition),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _city,
                    decoration: const InputDecoration(
                      labelText: 'Lieu de retrait',
                    ),
                    items: [
                      for (final c in const [
                        'Tunis',
                        'Sousse',
                        'Sfax',
                        'Hammamet',
                        'Djerba',
                        'Bizerte',
                        'Tozeur',
                      ])
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _city = v ?? _city),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _durationDays,
                    decoration: const InputDecoration(
                      labelText: 'Durée de la vente',
                    ),
                    items: [
                      for (final d in const [1, 3, 7, 14])
                        DropdownMenuItem(
                          value: d,
                          child: Text('$d jour${d > 1 ? 's' : ''}'),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _durationDays = v ?? _durationDays),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description (facultatif)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const NoticeBox(
                    icon: Icons.science_outlined,
                    message:
                        "La vente créée est ajoutée à la session locale "
                        "uniquement. Les photos utilisées sont génériques.",
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              14 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.publish_rounded, size: 18),
                label: const Text('Publier la vente'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _validInt(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Obligatoire';
    final parsed = int.tryParse(v);
    if (parsed == null || parsed <= 0) return 'Valeur invalide';
    return null;
  }

  static String? _validYear(String? value) {
    final v = value?.trim() ?? '';
    final parsed = int.tryParse(v);
    if (parsed == null) return 'Année invalide';
    if (parsed < 1980 || parsed > DateTime.now().year) {
      return 'Entre 1980 et ${DateTime.now().year}';
    }
    return null;
  }
}
