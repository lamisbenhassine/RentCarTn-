import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_cars.dart';
import '../../data/models/car.dart';
import '../../state/car_provider.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

/// Formulaire Create / Update d'un véhicule (champs métier simplifiés).
class CarFormScreen extends StatefulWidget {
  const CarFormScreen({super.key, this.carId});

  final String? carId;

  bool get isEditing => carId != null;

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  static const _maxPhotos = 5;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _price;
  late final TextEditingController _seats;
  late final TextEditingController _doors;
  late final TextEditingController _luggage;
  late final TextEditingController _description;
  late final TextEditingController _features;

  String _city = MockCars.villes.first;
  bool _airConditioning = true;
  bool _available = true;
  bool _saving = false;
  bool _picking = false;
  bool _ready = false;
  final List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _brand = TextEditingController();
    _model = TextEditingController();
    _year = TextEditingController(text: '${DateTime.now().year}');
    _price = TextEditingController(text: '100');
    _seats = TextEditingController(text: '5');
    _doors = TextEditingController(text: '4');
    _luggage = TextEditingController(text: '2');
    _description = TextEditingController();
    _features = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final provider = context.read<CarProvider>();
    await provider.load();

    if (widget.carId != null) {
      final existing = provider.carById(widget.carId!);
      if (existing != null && mounted) {
        _brand.text = existing.brand;
        _model.text = existing.model;
        _year.text = '${existing.year}';
        _price.text = existing.pricePerDay.toStringAsFixed(0);
        _seats.text = '${existing.seats}';
        _doors.text = '${existing.doors}';
        _luggage.text = '${existing.luggage}';
        _description.text = existing.description;
        _features.text = existing.features.join(', ');
        setState(() {
          _city = existing.city;
          _airConditioning = existing.airConditioning;
          _available = existing.available;
          _images
            ..clear()
            ..addAll(existing.images.where((u) => u.isNotEmpty));
          _ready = true;
        });
        return;
      }
    }

    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _price.dispose();
    _seats.dispose();
    _doors.dispose();
    _luggage.dispose();
    _description.dispose();
    _features.dispose();
    super.dispose();
  }

  List<String> get _parsedFeatures => _features.text
      .split(RegExp(r'[,;\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _pickPhotos() async {
    if (_images.length >= _maxPhotos) {
      AppSnack.info(context, 'Maximum $_maxPhotos photos.');
      return;
    }
    setState(() => _picking = true);
    try {
      final remaining = _maxPhotos - _images.length;
      final files = await _picker.pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 72,
        limit: remaining,
      );
      if (files.isEmpty || !mounted) return;

      final added = <String>[];
      for (final file in files) {
        if (_images.length + added.length >= _maxPhotos) break;
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
      setState(() => _images.addAll(added));
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Sélection de photo impossible.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<CarProvider>();
    final existing =
        widget.carId != null ? provider.carById(widget.carId!) : null;

    final car = Car(
      id: widget.carId ?? 'car-${DateTime.now().millisecondsSinceEpoch}',
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      year: int.parse(_year.text.trim()),
      category: existing?.category ?? CarCategory.economique,
      pricePerDay: double.parse(_price.text.trim().replaceAll(',', '.')),
      transmission: existing?.transmission ?? Transmission.manuelle,
      fuel: existing?.fuel ?? FuelType.essence,
      seats: int.parse(_seats.text.trim()),
      doors: int.parse(_doors.text.trim()),
      luggage: int.parse(_luggage.text.trim()),
      city: _city,
      rating: existing?.rating ?? 4.5,
      reviewCount: existing?.reviewCount ?? 0,
      images: List<String>.from(_images),
      description: _description.text.trim(),
      features: _parsedFeatures,
      available: _available,
      airConditioning: _airConditioning,
      bookedRanges: existing?.bookedRanges ?? const [],
      mileageLimitPerDay: existing?.mileageLimitPerDay ?? 300,
      deposit: existing?.deposit ?? 500,
      promoLabel: existing?.promoLabel,
      oldPricePerDay: existing?.oldPricePerDay,
    );

    try {
      if (widget.isEditing) {
        await provider.update(car);
        if (!mounted) return;
        AppSnack.success(context, 'Véhicule mis à jour.');
      } else {
        await provider.create(car);
        if (!mounted) return;
        AppSnack.success(context, 'Véhicule ajouté.');
      }
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(
        context,
        widget.isEditing
            ? 'Mise à jour impossible.'
            : 'Création impossible.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.carId;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await context.read<CarProvider>().delete(id);
      if (!mounted) return;
      AppSnack.success(context, 'Véhicule supprimé.');
      context.pop();
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Suppression impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pad = Responsive.value(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 28.0,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: widget.isEditing ? 'Modifier le véhicule' : 'Nouveau véhicule',
        subtitle: 'Marque · places · prix · photo · équipements · lieu',
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ContentContainer(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 120),
            children: [
              _PhotoSection(
                images: _images,
                picking: _picking,
                onUpload: _pickPhotos,
                onRemove: (i) => setState(() => _images.removeAt(i)),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _brand,
                decoration: const InputDecoration(
                  labelText: 'Marque *',
                  hintText: 'ex. Renault',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _model,
                decoration: const InputDecoration(
                  labelText: 'Modèle *',
                  hintText: 'ex. Clio 5',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _year,
                      decoration: const InputDecoration(labelText: 'Année *'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1990 || n > 2100) {
                          return 'Année invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(
                        labelText: 'Prix / jour (TND) *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'),
                        );
                        if (n == null || n <= 0) return 'Prix invalide';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seats,
                      decoration: const InputDecoration(
                        labelText: 'Places *',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1 || n > 15) return '1–15';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _doors,
                      decoration: const InputDecoration(
                        labelText: 'Portes *',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 2 || n > 6) return '2–6';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _luggage,
                      decoration: const InputDecoration(
                        labelText: 'Bagages *',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 0 || n > 10) return '0–10';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'Lieu *'),
                items: [
                  for (final city in MockCars.villes)
                    DropdownMenuItem(value: city, child: Text(city)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _city = v);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Climatisation'),
                value: _airConditioning,
                onChanged: (v) => setState(() => _airConditioning = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible à la location'),
                value: _available,
                onChanged: (v) => setState(() => _available = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _features,
                decoration: const InputDecoration(
                  labelText: 'Équipements disponibles',
                  hintText: 'GPS, Caméra de recul, Bluetooth…',
                  helperText: 'Séparez par des virgules',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving || _picking ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? 'Enregistrer' : 'Ajouter'),
          ),
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.images,
    required this.picking,
    required this.onUpload,
    required this.onRemove,
  });

  final List<String> images;
  final bool picking;
  final VoidCallback onUpload;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos du véhicule',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          images.isEmpty
              ? 'Ajoutez jusqu\'à 5 photos (galerie / fichiers).'
              : '${images.length} / 5 photo${images.length > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
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
          onPressed: picking || images.length >= 5 ? null : onUpload,
          icon: picking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_rounded, size: 20),
          label: Text(picking ? 'Chargement…' : 'Uploader une photo'),
        ),
      ],
    );
  }
}
