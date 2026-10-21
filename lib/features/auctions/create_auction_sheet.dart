import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/auction.dart';
import '../../data/models/car.dart';
import '../../state/auction_provider.dart';
import '../../state/car_provider.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';

/// Formulaire admin : choisir un véhicule CRUD + infos enchère + durée + prix.
class CreateAuctionSheet extends StatefulWidget {
  const CreateAuctionSheet({super.key});

  @override
  State<CreateAuctionSheet> createState() => _CreateAuctionSheetState();
}

class _CreateAuctionSheetState extends State<CreateAuctionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _mileage = TextEditingController();
  final _startPrice = TextEditingController(text: '15000');
  final _extraInfo = TextEditingController();
  final _description = TextEditingController();
  final _durationMinutes = TextEditingController(text: '30');

  Car? _selected;
  VehicleCondition _condition = VehicleCondition.bon;
  bool _hadAccident = false;
  bool _saving = false;
  bool _ready = false;

  /// Suggestions rapides ; le champ minutes reste libre (1, 5, 30…).
  static const _durationSuggestions = <(String, int)>[
    ('1 min', 1),
    ('5 min', 5),
    ('15 min', 15),
    ('30 min', 30),
    ('1 heure', 60),
    ('2 heures', 120),
  ];

  Duration get _duration {
    final minutes = int.tryParse(_durationMinutes.text.trim()) ?? 30;
    return Duration(minutes: minutes.clamp(1, 60 * 24 * 7));
  }

  void _applyDurationSuggestion(int minutes) {
    setState(() => _durationMinutes.text = '$minutes');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cars = context.read<CarProvider>();
      final auctions = context.read<AuctionProvider>();
      await cars.load();
      await auctions.load();
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _mileage.dispose();
    _startPrice.dispose();
    _extraInfo.dispose();
    _description.dispose();
    _durationMinutes.dispose();
    super.dispose();
  }

  void _selectCar(Car car) {
    setState(() {
      _selected = car;
      _mileage.text = '';
      _description.text = car.description;
      _extraInfo.clear();
    });
  }

  Future<void> _submit() async {
    if (_selected == null) {
      AppSnack.error(context, 'Sélectionnez un véhicule du parc.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final auction = await context.read<AuctionProvider>().createFromCar(
            car: _selected!,
            mileage: int.parse(_mileage.text.trim()),
            condition: _condition,
            hadAccident: _hadAccident,
            extraInfo: _extraInfo.text.trim(),
            description: _description.text.trim(),
            startingPrice: double.parse(
              _startPrice.text.trim().replaceAll(',', '.'),
            ),
            duration: _duration,
          );
      if (!mounted) return;
      Navigator.of(context).pop(auction);
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Publication impossible.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>().allCars;
    final busyIds = context.watch<AuctionProvider>().carIdsInActiveAuction;
    final available = cars.where((c) => !busyIds.contains(c.id)).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.98,
      minChildSize: 0.55,
      builder: (context, controller) {
        if (!_ready) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
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
                      'Mettre un véhicule aux enchères',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    const Text(
                      '1. Choisir un véhicule du parc',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (cars.isEmpty)
                      const NoticeBox(
                        icon: Icons.directions_car_outlined,
                        title: 'Parc vide',
                        message:
                            'Ajoutez d\'abord des véhicules dans Catalogue → Gérer.',
                      )
                    else if (available.isEmpty)
                      const NoticeBox(
                        icon: Icons.gavel_rounded,
                        color: AppColors.warning,
                        title: 'Tous déjà en vente',
                        message:
                            'Chaque véhicule actif du parc est déjà aux enchères.',
                      )
                    else
                      ...[
                        for (final car in available)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CarPickTile(
                              car: car,
                              selected: _selected?.id == car.id,
                              onTap: () => _selectCar(car),
                            ),
                          ),
                      ],
                    if (_selected != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '2. Infos enchère (en plus du véhicule)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selected!.fullName} · ${_selected!.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Âge : ${DateTime.now().year - _selected!.year} an(s) · '
                              '${_selected!.seats} places · ${_selected!.city}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mileage,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Kilométrage *',
                          suffixText: 'km',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 0) return 'Obligatoire';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<VehicleCondition>(
                        initialValue: _condition,
                        decoration: const InputDecoration(
                          labelText: 'État / santé du véhicule *',
                        ),
                        items: [
                          for (final c in VehicleCondition.values)
                            DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _condition = v);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Le véhicule a eu un accident'),
                        value: _hadAccident,
                        onChanged: (v) => setState(() => _hadAccident = v),
                      ),
                      TextFormField(
                        controller: _extraInfo,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Autres informations',
                          hintText: 'Entretien, pièces changées…',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description de la vente',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '3. Prix et durée',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _startPrice,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Prix de départ *',
                          suffixText: 'TND',
                          helperText: 'Surenchère fixe : +500 TND',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) return 'Prix invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Durée de l\'enchère',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (label, minutes) in _durationSuggestions)
                            ChoiceChip(
                              label: Text(label),
                              selected:
                                  int.tryParse(_durationMinutes.text.trim()) ==
                                  minutes,
                              onSelected: (_) =>
                                  _applyDurationSuggestion(minutes),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _durationMinutes,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Durée libre (minutes) *',
                          hintText: 'ex. 1, 5, 30, 90…',
                          suffixText: 'min',
                          helperText:
                              'Choisis une suggestion ou tape n\'importe '
                              'quelle durée (1 min minimum).',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 1) {
                            return 'Au moins 1 minute';
                          }
                          if (n > 60 * 24 * 7) {
                            return 'Maximum 7 jours';
                          }
                          return null;
                        },
                      ),
                    ],
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
                  onPressed: _saving || _selected == null ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_rounded, size: 18),
                  label: Text(
                    _saving ? 'Publication…' : 'Publier aux enchères',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CarPickTile extends StatelessWidget {
  const _CarPickTile({
    required this.car,
    required this.selected,
    required this.onTap,
  });

  final Car car;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.08)
          : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              CarImage(
                url: car.mainImage,
                height: 56,
                width: 76,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${car.year} · ${car.city} · '
                      '${Formatters.moneyShort(car.pricePerDay)}/j',
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
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
