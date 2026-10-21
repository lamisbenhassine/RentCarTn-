import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/exam.dart';
import '../../data/services/gemini_service.dart';
import '../../state/exam_provider.dart';
import '../../state/learning_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

/// Formulaire Create / Update d'un examen + ses questions.
class ExamFormScreen extends StatefulWidget {
  const ExamFormScreen({super.key, this.examId});

  final String? examId;

  bool get isEditing => examId != null;

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gemini = GeminiService();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _passing;

  bool _isFinal = true;
  bool _isPublished = true;
  bool _saving = false;
  bool _generating = false;
  bool _ready = false;
  List<_QuestionDraft> _questions = [];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _description = TextEditingController();
    _passing = TextEditingController(text: '70');
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final provider = context.read<ExamProvider>();
    final learning = context.read<LearningProvider>();
    await Future.wait([
      provider.load(),
      learning.loadSigns(),
    ]);

    if (widget.examId != null) {
      final existing = provider.byId(widget.examId!);
      if (existing != null && mounted) {
        _title.text = existing.title;
        _description.text = existing.description;
        _passing.text = '${existing.passingPercent}';
        _isFinal = existing.isFinal;
        _isPublished = existing.isPublished;
        _questions = [
          for (final q in existing.questions) _QuestionDraft.fromModel(q),
        ];
      }
    }

    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _gemini.dispose();
    _title.dispose();
    _description.dispose();
    _passing.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft.empty());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index).dispose();
    });
  }

  Future<void> _generateWithAi() async {
    if (_generating || _saving) return;

    if (_questions.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remplacer les questions ?'),
          content: const Text(
            'La génération IA va remplacer les questions actuelles '
            'par de nouvelles questions basées sur les panneaux et règles.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Générer'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _generating = true);

    try {
      final learning = context.read<LearningProvider>();
      await learning.loadSigns();
      final signs = learning.signs;

      final result = await _gemini.generateExam(
        signs: signs,
        rules: learning.rules,
        questionCount: 8,
      );

      if (!mounted) return;

      if (!result.ok) {
        AppSnack.error(
          context,
          result.message ?? 'Génération impossible.',
        );
        return;
      }

      for (final q in _questions) {
        q.dispose();
      }

      setState(() {
        if (_title.text.trim().isEmpty && result.title != null) {
          _title.text = result.title!;
        }
        if (_description.text.trim().isEmpty && result.description != null) {
          _description.text = result.description!;
        }
        _questions = [
          for (final q in result.questions) _QuestionDraft.fromModel(q),
        ];
      });

      AppSnack.success(
        context,
        '${result.questions.length} questions générées par Gemini. '
        'Vérifie-les avant d\'enregistrer.',
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      AppSnack.error(context, 'Ajoutez au moins une question.');
      return;
    }

    for (var i = 0; i < _questions.length; i++) {
      final err = _questions[i].validate();
      if (err != null) {
        AppSnack.error(context, 'Question ${i + 1} : $err');
        return;
      }
    }

    setState(() => _saving = true);
    final exam = Exam(
      id: widget.examId ?? 'exam-${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      description: _description.text.trim(),
      passingPercent: int.parse(_passing.text.trim()),
      isFinal: _isFinal,
      isPublished: _isPublished,
      questions: [
        for (var i = 0; i < _questions.length; i++)
          _questions[i].toModel(sortOrder: i),
      ],
    );

    try {
      final provider = context.read<ExamProvider>();
      if (widget.isEditing) {
        await provider.update(exam);
        if (!mounted) return;
        AppSnack.success(context, 'Examen mis à jour.');
      } else {
        await provider.create(exam);
        if (!mounted) return;
        AppSnack.success(context, 'Examen créé.');
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
    final id = widget.examId;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet examen ?'),
        content: const Text(
          'Toutes les questions associées seront également supprimées.',
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
      await context.read<ExamProvider>().delete(id);
      if (!mounted) return;
      AppSnack.success(context, 'Examen supprimé.');
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
        title: widget.isEditing ? 'Modifier l\'examen' : 'Nouvel examen',
        subtitle: '${_questions.length} question'
            '${_questions.length > 1 ? 's' : ''}',
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
              40,
            ),
            children: [
              // Bouton IA en premier — bien visible sans scroller.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.accent,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Génération IA (Google Gemini)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crée automatiquement des QCM à partir des panneaux '
                      'et des règles. Tu pourras ensuite modifier chaque '
                      'question à la main.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed:
                          (_generating || _saving) ? null : _generateWithAi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: _generating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _generating
                            ? 'Génération en cours…'
                            : 'Générer avec l\'IA (Gemini)',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'examen',
                  hintText: 'Ex. Examen blanc final',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passing,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil de réussite (%)',
                  suffixText: '%',
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 100) {
                    return 'Entre 1 et 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Examen final'),
                subtitle: const Text(
                  'Marqué comme examen de synthèse du module',
                ),
                value: _isFinal,
                onChanged: (v) => setState(() => _isFinal = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publié'),
                subtitle: const Text(
                  'Visible pour les utilisateurs une fois enregistré',
                ),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: (_generating || _saving) ? null : _addQuestion,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter une question'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_questions.isEmpty)
                const NoticeBox(
                  icon: Icons.quiz_outlined,
                  message:
                      'Aucune question. Utilise « Générer avec l\'IA » '
                      'ou ajoute des QCM manuellement.',
                )
              else
                for (var i = 0; i < _questions.length; i++)
                  _QuestionEditor(
                    index: i,
                    draft: _questions[i],
                    onRemove: () => _removeQuestion(i),
                    onChanged: () => setState(() {}),
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
                        ? 'Enregistrer l\'examen'
                        : 'Créer l\'examen',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionDraft {
  _QuestionDraft({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory _QuestionDraft.empty() {
    return _QuestionDraft(
      id: 'q-${DateTime.now().microsecondsSinceEpoch}',
      question: TextEditingController(),
      options: [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ],
      correctIndex: 0,
      explanation: TextEditingController(),
    );
  }

  factory _QuestionDraft.fromModel(ExamQuestion q) {
    final opts = List<TextEditingController>.generate(4, (i) {
      return TextEditingController(
        text: i < q.options.length ? q.options[i] : '',
      );
    });
    return _QuestionDraft(
      id: q.id,
      question: TextEditingController(text: q.question),
      options: opts,
      correctIndex: q.correctIndex.clamp(0, 3),
      explanation: TextEditingController(text: q.explanation),
    );
  }

  final String id;
  final TextEditingController question;
  final List<TextEditingController> options;
  int correctIndex;
  final TextEditingController explanation;

  void dispose() {
    question.dispose();
    for (final o in options) {
      o.dispose();
    }
    explanation.dispose();
  }

  String? validate() {
    if (question.text.trim().isEmpty) return 'énoncé manquant';
    final filled = options
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (filled.length < 2) return 'au moins 2 options';
    if (correctIndex >= filled.length) {
      return 'bonne réponse invalide';
    }
    if (explanation.text.trim().isEmpty) return 'explication manquante';
    return null;
  }

  ExamQuestion toModel({required int sortOrder}) {
    final filled = options
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    return ExamQuestion(
      id: id,
      question: question.text.trim(),
      options: filled,
      correctIndex: correctIndex.clamp(0, filled.length - 1),
      explanation: explanation.text.trim(),
      sortOrder: sortOrder,
    );
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Supprimer la question',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: draft.question,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Énoncé',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < draft.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Marquer comme bonne réponse',
                      onPressed: () {
                        draft.correctIndex = i;
                        onChanged();
                      },
                      icon: Icon(
                        i == draft.correctIndex
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: i == draft.correctIndex
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: draft.options[i],
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1}'
                              '${i == draft.correctIndex ? ' (bonne réponse)' : ''}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: draft.explanation,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Explication (après réponse)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
