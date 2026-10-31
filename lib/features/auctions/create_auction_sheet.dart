import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/gemini_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/auction.dart';
import '../../data/models/car.dart';
import '../../data/services/gemini_service.dart';
import '../../state/auction_provider.dart';
import '../../state/car_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/notification_provider.dart';
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

  final _gemini = GeminiService();
  final _picker = ImagePicker();

  /// Véhicules inclus dans cette vacation (plusieurs possibles).
  final LinkedHashSet<String> _selectedIds = LinkedHashSet<String>();

  /// Photos ajoutées à la vente (affichées en premier dans la galerie).
  final List<String> _auctionPhotos = [];
  static const _maxPhotos = 8;

  /// Véhicule dont on édite les infos (km, état, prix…).
  Car? _focused;
  VehicleCondition _condition = VehicleCondition.bon;
  bool _hadAccident = false;
  bool _saving = false;
  bool _ready = false;
  bool _estimating = false;
  bool _pickingPhotos = false;
  String? _priceRationale;
  double? _priceMin;
  double? _priceMax;

  /// Brouillons par véhicule : changer de focus ne perd plus le km saisi.
  final Map<String, _AuctionDraft> _drafts = {};

  /// false = démarre tout de suite ; true = date/heure choisies.
  bool _scheduleStart = false;
  DateTime _startAt = DateTime.now();

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

  DateTime get _effectiveStartAt {
    if (!_scheduleStart) return DateTime.now();
    // Si la date choisie est déjà passée, on démarre immédiatement.
    final now = DateTime.now();
    return _startAt.isBefore(now) ? now : _startAt;
  }

  void _applyDurationSuggestion(int minutes) {
    setState(() => _durationMinutes.text = '$minutes');
  }

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final initial = _startAt.isBefore(now) ? now : _startAt;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date d\'ouverture',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Heure d\'ouverture',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduleStart = true;
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
    _gemini.dispose();
    super.dispose();
  }

  void _saveCurrentDraft() {
    final current = _focused;
    if (current == null) return;
    _drafts[current.id] = _AuctionDraft(
      mileage: _mileage.text,
      condition: _condition,
      hadAccident: _hadAccident,
      extraInfo: _extraInfo.text,
      description: _description.text,
      startPrice: _startPrice.text,
      priceRationale: _priceRationale,
      priceMin: _priceMin,
      priceMax: _priceMax,
    );
  }

  void _loadDraftFor(Car car) {
    final draft = _drafts[car.id];
    _focused = car;
    _mileage.text = draft?.mileage ?? '';
    _condition = draft?.condition ?? VehicleCondition.bon;
    _hadAccident = draft?.hadAccident ?? false;
    _extraInfo.text = draft?.extraInfo ?? '';
    _description.text = draft?.description ?? car.description;
    _startPrice.text = draft?.startPrice ?? '15000';
    _priceRationale = draft?.priceRationale;
    _priceMin = draft?.priceMin;
    _priceMax = draft?.priceMax;
  }

  void _toggleCar(Car car) {
    _saveCurrentDraft();
    setState(() {
      if (_selectedIds.contains(car.id)) {
        _selectedIds.remove(car.id);
        if (_focused?.id == car.id) {
          if (_selectedIds.isEmpty) {
            _focused = null;
          } else {
            final nextId = _selectedIds.last;
            final next = context
                .read<CarProvider>()
                .allCars
                .where((c) => c.id == nextId)
                .firstOrNull;
            if (next != null) {
              _loadDraftFor(next);
            } else {
              _focused = null;
            }
          }
        }
      } else {
        _selectedIds.add(car.id);
        _loadDraftFor(car);
        // Enregistre un brouillon dès la sélection (km/prix à compléter).
        _drafts[car.id] = _AuctionDraft(
          mileage: _mileage.text,
          condition: _condition,
          hadAccident: _hadAccident,
          extraInfo: _extraInfo.text,
          description: _description.text,
          startPrice: _startPrice.text,
          priceRationale: _priceRationale,
          priceMin: _priceMin,
          priceMax: _priceMax,
        );
      }
    });
  }

  void _focusCar(Car car) {
    if (!_selectedIds.contains(car.id)) {
      _toggleCar(car);
      return;
    }
    if (_focused?.id == car.id) return;
    _saveCurrentDraft();
    setState(() => _loadDraftFor(car));
  }

  Future<void> _pickAuctionPhotos() async {
    if (_auctionPhotos.length >= _maxPhotos) {
      AppSnack.info(context, 'Maximum $_maxPhotos photos pour la vente.');
      return;
    }
    setState(() => _pickingPhotos = true);
    try {
      final remaining = _maxPhotos - _auctionPhotos.length;
      final files = await _picker.pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 72,
        limit: remaining,
      );
      if (files.isEmpty || !mounted) return;

      final added = <String>[];
      for (final file in files) {
        if (_auctionPhotos.length + added.length >= _maxPhotos) break;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        final mime = _mimeFromName(file.name);
        added.add('data:$mime;base64,${base64Encode(bytes)}');
      }
      if (!mounted) return;
      if (added.isEmpty) {
        AppSnack.error(context, 'Impossible de lire la photo.');
        return;
      }
      setState(() => _auctionPhotos.addAll(added));
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Sélection de photo impossible.');
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _estimateStartPrice() async {
    if (_focused == null) {
      AppSnack.error(context, 'Sélectionnez d\'abord un véhicule.');
      return;
    }
    final mileage = int.tryParse(_mileage.text.trim());
    if (mileage == null || mileage < 0) {
      AppSnack.error(
        context,
        'Indique le kilométrage avant l\'estimation IA.',
      );
      return;
    }
    if (!GeminiConfig.isConfigured) {
      AppSnack.error(
        context,
        'Clé Gemini manquante (gemini_secrets.dart).',
      );
      return;
    }

    setState(() => _estimating = true);
    try {
      final result = await _gemini.estimateAuctionStartPrice(
        car: _focused!,
        mileage: mileage,
        condition: _condition,
        hadAccident: _hadAccident,
        extraInfo: _extraInfo.text.trim(),
        description: _description.text.trim(),
      );
      if (!mounted) return;
      if (!result.ok || result.startingPrice == null) {
        AppSnack.error(
          context,
          result.message ?? 'Estimation IA impossible.',
        );
        return;
      }
      setState(() {
        _startPrice.text = result.startingPrice!.round().toString();
        _priceRationale = result.rationale;
        _priceMin = result.minPrice;
        _priceMax = result.maxPrice;
      });
      AppSnack.success(
        context,
        'Prix estimé : ${Formatters.moneyShort(result.startingPrice!)}',
      );
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  String? _validateDraft(Car car, _AuctionDraft? draft) {
    final mileage = int.tryParse((draft?.mileage ?? '').trim());
    if (mileage == null || mileage < 0) {
      return 'Kilométrage manquant pour ${car.fullName}.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) {
      AppSnack.error(context, 'Sélectionnez au moins un véhicule.');
      return;
    }
    _saveCurrentDraft();

    final lotPrice = double.tryParse(
      _startPrice.text.trim().replaceAll(',', '.'),
    );
    if (lotPrice == null || lotPrice <= 0) {
      AppSnack.error(context, 'Indique le prix de départ de la vente.');
      return;
    }

    final cars = context.read<CarProvider>().allCars;
    final byId = {for (final c in cars) c.id: c};
    final items = <({
      Car car,
      int mileage,
      VehicleCondition condition,
      bool hadAccident,
      String extraInfo,
      String description,
    })>[];

    for (final id in _selectedIds) {
      final car = byId[id];
      if (car == null) continue;
      final draft = _drafts[id];
      final error = _validateDraft(car, draft);
      if (error != null) {
        _focusCar(car);
        AppSnack.error(context, error);
        return;
      }
      items.add((
        car: car,
        mileage: int.parse(draft!.mileage.trim()),
        condition: draft.condition,
        hadAccident: draft.hadAccident,
        extraInfo: draft.extraInfo.trim(),
        description: draft.description.trim(),
      ));
    }

    if (items.isEmpty) {
      AppSnack.error(context, 'Aucun véhicule valide à publier.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final created = await context.read<AuctionProvider>().createLot(
            items: items,
            startingPrice: lotPrice,
            duration: _duration,
            startAt: _effectiveStartAt,
            images: List<String>.from(_auctionPhotos),
          );
      if (!mounted) return;

      // Retiré de la location : véhicule mis en vente.
      final carProvider = context.read<CarProvider>();
      final cart = context.read<CartProvider>();
      for (final item in items) {
        final inCart = cart.itemForCar(item.car.id);
        if (inCart != null) cart.remove(inCart.id);
        await carProvider.delete(item.car.id);
      }

      if (!mounted) return;
      await context.read<NotificationProvider>().notifyNewAuction(created);
      if (!mounted) return;
      Navigator.of(context).pop(<Auction>[created]);
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
                  Expanded(
                    child: Text(
                      _selectedIds.length <= 1
                          ? 'Mettre aux enchères'
                          : 'Mettre ${_selectedIds.length} véhicules aux enchères',
                      style: const TextStyle(
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
                    Text(
                      '1. Choisir un ou plusieurs véhicules '
                      '(${_selectedIds.length} sélectionné'
                      '${_selectedIds.length > 1 ? 's' : ''})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Coche 1, 3 ou 10 voitures : elles forment UNE seule '
                      'enchère (lot). Tape une voiture pour ses infos (km…).',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.35,
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
                              checked: _selectedIds.contains(car.id),
                              focused: _focused?.id == car.id,
                              onToggle: () => _toggleCar(car),
                              onTap: () => _focusCar(car),
                            ),
                          ),
                      ],
                    if (_focused != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '2. Infos enchère — ${_focused!.fullName}',
                        style: const TextStyle(
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
                              '${_focused!.fullName} · ${_focused!.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Âge : ${DateTime.now().year - _focused!.year} an(s) · '
                              '${_focused!.seats} places · ${_focused!.city}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (_selectedIds.length > 1) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Complète le km / l\'état de chaque voiture. '
                                'Le prix ci-dessous est celui du LOT entier.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accent.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                        key: ValueKey('condition-${_focused!.id}-$_condition'),
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
                        '3. Photos de la vente',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ajoute des photos pour cette enchère (lot ou '
                        'véhicule). Elles s\'affichent en premier.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AuctionPhotoSection(
                        images: _auctionPhotos,
                        picking: _pickingPhotos,
                        maxPhotos: _maxPhotos,
                        onUpload: _pickAuctionPhotos,
                        onRemove: (i) =>
                            setState(() => _auctionPhotos.removeAt(i)),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '4. Date d\'ouverture',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'La vente (lot) apparaît tout de suite. Personne ne '
                        'peut enchérir avant la date choisie.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Maintenant'),
                            selected: !_scheduleStart,
                            onSelected: (_) => setState(() {
                              _scheduleStart = false;
                              _startAt = DateTime.now();
                            }),
                          ),
                          ChoiceChip(
                            label: const Text('Choisir une date'),
                            selected: _scheduleStart,
                            onSelected: (_) async {
                              if (_scheduleStart) return;
                              await _pickStartDateTime();
                            },
                          ),
                        ],
                      ),
                      if (_scheduleStart) ...[
                        const SizedBox(height: 10),
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ouverture des enchères',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.dateTime(_startAt),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _pickStartDateTime,
                                child: const Text('Modifier'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        _selectedIds.length > 1
                            ? '5. Prix du lot et durée'
                            : '5. Prix et durée',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedIds.length > 1
                            ? 'Un seul prix de départ pour tout le lot '
                                '(${_selectedIds.length} voitures). L\'IA '
                                'peut estimer à partir de la voiture en cours.'
                            : 'L\'IA estime le prix de départ à partir du '
                                'modèle, du km et de l\'état (marché Tunisie).',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _startPrice,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: _selectedIds.length > 1
                              ? 'Prix de départ du lot *'
                              : 'Prix de départ *',
                          suffixText: 'TND',
                          helperText: 'Surenchère fixe : +500 TND',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) return 'Prix invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _estimating || _saving
                              ? null
                              : _estimateStartPrice,
                          icon: _estimating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: Text(
                            _estimating
                                ? 'Estimation Gemini…'
                                : 'Estimer le prix avec l\'IA',
                          ),
                        ),
                      ),
                      if (_priceRationale != null &&
                          _priceRationale!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.psychology_rounded,
                                    size: 18,
                                    color: AppColors.accent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Analyse IA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              if (_priceMin != null && _priceMax != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Fourchette marché : '
                                  '${Formatters.moneyShort(_priceMin!)} – '
                                  '${Formatters.moneyShort(_priceMax!)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                _priceRationale!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                  onPressed:
                      _saving || _selectedIds.isEmpty ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_rounded, size: 18),
                  label: Text(
                    _saving
                        ? 'Publication…'
                        : _selectedIds.length > 1
                            ? (_scheduleStart
                                ? 'Planifier le lot (${_selectedIds.length} voitures)'
                                : 'Publier le lot (${_selectedIds.length} voitures)')
                            : (_scheduleStart
                                ? 'Planifier la vente'
                                : 'Publier aux enchères'),
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

class _AuctionPhotoSection extends StatelessWidget {
  const _AuctionPhotoSection({
    required this.images,
    required this.picking,
    required this.maxPhotos,
    required this.onUpload,
    required this.onRemove,
  });

  final List<String> images;
  final bool picking;
  final int maxPhotos;
  final VoidCallback onUpload;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          images.isEmpty
              ? 'Jusqu\'à $maxPhotos photos (galerie).'
              : '${images.length} / $maxPhotos photo${images.length > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        if (images.isNotEmpty)
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                return Stack(
                  children: [
                    CarImage(
                      url: images[i],
                      height: 112,
                      width: 148,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: AppColors.navy.withValues(alpha: 0.75),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onRemove(i),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i == 0)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'Principale',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        if (images.isNotEmpty) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: picking || images.length >= maxPhotos ? null : onUpload,
          icon: picking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined, size: 20),
          label: Text(
            picking ? 'Chargement…' : 'Ajouter des photos',
          ),
        ),
      ],
    );
  }
}

class _AuctionDraft {
  const _AuctionDraft({
    required this.mileage,
    required this.condition,
    required this.hadAccident,
    required this.extraInfo,
    required this.description,
    required this.startPrice,
    this.priceRationale,
    this.priceMin,
    this.priceMax,
  });

  final String mileage;
  final VehicleCondition condition;
  final bool hadAccident;
  final String extraInfo;
  final String description;
  final String startPrice;
  final String? priceRationale;
  final double? priceMin;
  final double? priceMax;
}

class _CarPickTile extends StatelessWidget {
  const _CarPickTile({
    required this.car,
    required this.checked,
    required this.focused,
    required this.onToggle,
    required this.onTap,
  });

  final Car car;
  final bool checked;
  final bool focused;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: focused
          ? AppColors.accent.withValues(alpha: 0.10)
          : checked
              ? AppColors.accent.withValues(alpha: 0.05)
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
              color: focused
                  ? AppColors.accent
                  : checked
                      ? AppColors.accent.withValues(alpha: 0.45)
                      : AppColors.border,
              width: focused ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: checked ? 'Retirer' : 'Ajouter à la vacation',
                onPressed: onToggle,
                icon: Icon(
                  checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: checked ? AppColors.accent : AppColors.border,
                ),
              ),
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
                    if (focused)
                      const Text(
                        'En cours d\'édition',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
