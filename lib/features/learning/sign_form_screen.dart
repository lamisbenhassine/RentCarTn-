import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/learning.dart';
import '../../state/learning_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import 'sign_widget.dart';

/// Formulaire Create / Update d'un panneau.
class SignFormScreen extends StatefulWidget {
  const SignFormScreen({
    super.key,
    this.signId,
    this.initialCategory,
  });

  final String? signId;
  final SignCategory? initialCategory;

  bool get isEditing => signId != null;

  @override
  State<SignFormScreen> createState() => _SignFormScreenState();
}

class _SignFormScreenState extends State<SignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _meaning;
  late final TextEditingController _advice;
  late final TextEditingController _glyph;

  SignCategory _category = SignCategory.danger;
  SignShape _shape = SignShape.triangle;
  ContentTrust _trust = ContentTrust.aVerifier;
  bool _saving = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _meaning = TextEditingController();
    _advice = TextEditingController();
    _glyph = TextEditingController(text: '!');
    _category = widget.initialCategory ?? SignCategory.danger;
    _shape = _defaultShapeFor(_category);

    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final learning = context.read<LearningProvider>();
    await learning.loadSigns();

    if (widget.signId != null) {
      final existing = learning.signById(widget.signId!);
      if (existing != null && mounted) {
        _name.text = existing.name;
        _meaning.text = existing.meaning;
        _advice.text = existing.advice;
        _glyph.text = existing.glyph;
        setState(() {
          _category = existing.category;
          _shape = existing.shape;
          _trust = existing.trust;
          _ready = true;
        });
        return;
      }
    }

    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _meaning.dispose();
    _advice.dispose();
    _glyph.dispose();
    super.dispose();
  }

  SignShape _defaultShapeFor(SignCategory category) => switch (category) {
        SignCategory.danger => SignShape.triangle,
        SignCategory.interdiction => SignShape.cercle,
        SignCategory.obligation => SignShape.cercle,
        SignCategory.indication => SignShape.carre,
        SignCategory.priorite => SignShape.triangle,
      };

  RoadSign get _preview => RoadSign(
        id: widget.signId ?? 'preview',
        name: _name.text.trim().isEmpty ? 'Aperçu' : _name.text.trim(),
        category: _category,
        shape: _shape,
        meaning: _meaning.text,
        advice: _advice.text,
        glyph: _glyph.text.trim().isEmpty ? '?' : _glyph.text.trim(),
        trust: _trust,
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final learning = context.read<LearningProvider>();
    final sign = RoadSign(
      id: widget.signId ??
          'sg-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      shape: _shape,
      meaning: _meaning.text.trim(),
      advice: _advice.text.trim(),
      glyph: _glyph.text.trim(),
      trust: _trust,
    );

    try {
      if (widget.isEditing) {
        await learning.updateSign(sign);
        if (!mounted) return;
        AppSnack.success(context, 'Panneau mis à jour.');
      } else {
        await learning.createSign(sign);
        if (!mounted) return;
        AppSnack.success(context, 'Panneau ajouté.');
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
    final id = widget.signId;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce panneau ?'),
        content: Text(
          '« ${_name.text.trim().isEmpty ? 'Ce panneau' : _name.text.trim()} » '
          'sera retiré définitivement.',
        ),
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
      await context.read<LearningProvider>().deleteSign(id);
      if (!mounted) return;
      AppSnack.success(context, 'Panneau supprimé.');
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: widget.isEditing ? 'Modifier le panneau' : 'Nouveau panneau',
        subtitle: _category.shortLabel,
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _saving ? null : _delete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
      body: ContentContainer(
        child: Form(
          key: _formKey,
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
              32,
            ),
            children: [
              Center(child: RoadSignWidget(sign: _preview, size: 96)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nom du panneau',
                  hintText: 'Ex. Virage dangereux à droite',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<SignCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [
                  for (final c in SignCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(c.shortLabel),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _category = v;
                    _shape = _defaultShapeFor(v);
                  });
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<SignShape>(
                initialValue: _shape,
                decoration: const InputDecoration(labelText: 'Forme'),
                items: [
                  for (final s in SignShape.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(_shapeLabel(s)),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _shape = v);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _glyph,
                decoration: const InputDecoration(
                  labelText: 'Symbole (glyphe)',
                  hintText: 'Ex. 50, →, P, STOP',
                  helperText: 'Texte court affiché au centre du panneau',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _meaning,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Signification',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _advice,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Conseil / contexte Tunisie',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ContentTrust>(
                initialValue: _trust,
                decoration: const InputDecoration(
                  labelText: 'Fiabilité du contenu',
                ),
                items: [
                  for (final t in ContentTrust.values)
                    DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _trust = v);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          widget.isEditing
                              ? Icons.save_rounded
                              : Icons.add_rounded,
                        ),
                  label: Text(
                    widget.isEditing
                        ? 'Enregistrer les modifications'
                        : 'Créer le panneau',
                  ),
                ),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Supprimer ce panneau'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _shapeLabel(SignShape shape) => switch (shape) {
        SignShape.triangle => 'Triangle',
        SignShape.cercle => 'Cercle',
        SignShape.carre => 'Carré',
        SignShape.octogone => 'Octogone',
        SignShape.losange => 'Losange',
      };
}
