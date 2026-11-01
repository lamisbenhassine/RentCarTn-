import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/gemini_config.dart';
import '../../core/router/app_router.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/auction.dart';
import '../../data/models/complaint.dart';
import '../../data/models/complaint_draft.dart';
import '../../data/models/reservation.dart';
import '../../data/services/complaint_ai.dart';
import '../../data/services/complaint_photo_store.dart';
import '../../data/services/complaint_trust_service.dart';
import '../../data/services/gemini_service.dart';
import '../../l10n/l10n.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/complaint_provider.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';
import 'complaint_l10n.dart';
import 'complaint_mail.dart';
import 'widgets/complaint_photo.dart';

/// Création d'une réclamation, ou modification si [complaintId] est donné.
/// [reservationId] pré-sélectionne une réservation (depuis son détail).
class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({
    super.key,
    this.complaintId,
    this.reservationId,
    this.draft,
  });

  final String? complaintId;
  final String? reservationId;

  /// Proposition de l'Assistant RentCar (« Modifier ») : pré-remplit le
  /// formulaire, le client vérifie puis envoie lui-même.
  final ComplaintDraft? draft;

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

enum _LinkType { none, reservation, auction }

/// Réponse à « Avant d'envoyer, avez-vous essayé ? ».
enum _QuickFixChoice { resolved, sendAnyway }

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  static const _titleMin = 5;
  static const _titleMax = 80;
  static const _descMin = 20;
  static const _descMax = 1000;
  static const _maxPhotos = 4;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  ComplaintCategory? _category;
  ComplaintPriority _priority = ComplaintPriority.moyenne;
  _LinkType _link = _LinkType.none;
  String? _reservationId;
  String? _auctionId;

  /// Erreurs hors champs texte (affichées après « Envoyer »).
  bool _showCategoryError = false;
  bool _showLinkError = false;

  bool _saving = false;
  bool _saveFailed = false;

  /// Réclamation créée → écran de confirmation avec la référence.
  Complaint? _created;
  Future<ComplaintMailResult>? _mail;

  /// Mode modification.
  Complaint? _editing;
  bool get _isEdit => widget.complaintId != null;

  // --- Photos (preuves) ---
  late final ComplaintPhotoStore _store;
  List<String> _photos = [];
  bool _addingPhoto = false;

  /// Copiées pendant cette saisie : supprimées si on quitte sans envoyer.
  final Set<String> _addedNow = {};

  /// Photos d'origine retirées (modification) : supprimées après
  /// l'enregistrement seulement.
  final List<String> _removedOriginals = [];

  /// Vrai une fois la réclamation enregistrée avec ses photos.
  bool _photosCommitted = false;

  // --- Position (« Joindre ma position ») ---
  bool _attachLocation = false;

  /// L'utilisateur a touché l'interrupteur : on ne l'active plus tout seul.
  bool _locationTouched = false;
  Future<DetectedLocation?>? _locating;
  DetectedLocation? _location;
  LocationFailure? _locationFailure;

  // --- Suggestion IA (Gemini) ---
  /// Quota gratuit limité : 2,5 s de pause, et une seule analyse
  /// automatique par formulaire (ensuite : bouton « Analyser avec l'IA »).
  static const _aiDebounce = Duration(milliseconds: 2500);
  bool _autoAnalysisDone = false;
  final _gemini = GeminiService();
  Timer? _aiTimer;
  bool _aiAnalyzing = false;

  /// Dernière analyse reçue et le texte (titre + description) analysé.
  ComplaintAiAnalysis? _ai;
  String? _aiKey;

  /// Le client a accepté ou refusé la suggestion : carte masquée.
  bool _aiDecided = false;

  // --- « Améliorer mon message » et solutions rapides ---
  bool _improving = false;
  bool _checkingFixes = false;

  /// Solutions déjà montrées et « Envoyer quand même » choisi : on ne
  /// redemande pas (ex. nouvel essai après un échec d'enregistrement).
  bool _quickFixesDone = false;

  /// Reformulation par Gemini, avec avant / après : le client accepte ou
  /// refuse. Rien n'est remplacé sans son accord.
  Future<void> _improveText() async {
    final l = context.l10n;
    final before = _description.text.trim();
    if (before.length < _descMin) {
      _formKey.currentState?.validate();
      return;
    }
    setState(() => _improving = true);
    final after = await _gemini.improveComplaintText(
      title: _title.text,
      description: before,
    );
    if (!mounted) return;
    setState(() => _improving = false);
    if (_description.text.trim() != before) return; // modifié entre-temps
    if (after == null) {
      AppSnack.info(
        context,
        GeminiService.quotaReached ? l.aiQuotaReached : l.aiImproveFailed,
      );
      return;
    }
    if (after == before) {
      AppSnack.info(context, l.aiImproveSame);
      return;
    }

    final accept = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ImproveSheet(before: before, after: after),
    );
    if (accept != true || !mounted) return;
    _description.text = after; // relance aussi l'analyse IA (debounce)
    AppSnack.success(context, l.aiImproveApplied);
  }

  /// Propose 1 à 3 solutions rapides avant de créer la réclamation.
  /// `true` → on envoie ; `false` → on n'envoie pas (résolu ou fermé).
  /// IA indisponible, rien à proposer ou panne urgente → `true` directement.
  Future<bool> _confirmAfterQuickFixes() async {
    final category = _category!;
    if (_quickFixesDone || !GeminiConfig.isConfigured) return true;
    if (category == ComplaintCategory.panne &&
        _priority == ComplaintPriority.urgente) {
      return true; // panne urgente : pas de détour, on envoie
    }

    setState(() => _checkingFixes = true);
    List<String> fixes;
    try {
      fixes = await _gemini
          .suggestQuickFixes(
            category: category,
            title: _title.text,
            description: _description.text,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[ComplaintAI] Solutions rapides ignorées : $e');
      fixes = const [];
    }
    if (!mounted) return false;
    setState(() => _checkingFixes = false);
    if (fixes.isEmpty) return true;

    final choice = await showModalBottomSheet<_QuickFixChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _QuickFixSheet(fixes: fixes),
    );
    if (!mounted) return false;
    switch (choice) {
      case _QuickFixChoice.sendAnyway:
        _quickFixesDone = true;
        return true;
      case _QuickFixChoice.resolved:
        // Rien n'est créé ; les photos ajoutées sont supprimées au dispose.
        AppSnack.success(context, context.l10n.quickFixResolvedMsg);
        context.canPop() ? context.pop() : context.go(Routes.complaints);
        return false;
      case null:
        return false; // feuille fermée : retour au formulaire
    }
  }

  /// Texte vu au dernier changement (ignore les simples mouvements du curseur).
  String _lastKey = '';

  String get _textKey => '${_title.text.trim()}\n${_description.text.trim()}';

  bool get _textReady =>
      _title.text.trim().length >= _titleMin &&
      _description.text.trim().length >= _descMin;

  /// Analyse à jour avec le texte actuel (enregistrée avec la réclamation).
  ComplaintAiAnalysis? get _freshAi => _aiKey == _textKey ? _ai : null;

  /// Saisie terminée depuis 2,5 s (titre ≥ 5, description ≥ 20) → analyse
  /// automatique, UNE fois. Les suivantes : bouton « Analyser avec l'IA ».
  void _onTextChanged() {
    final key = _textKey;
    if (key == _lastKey) return;
    _lastKey = key;
    _aiTimer?.cancel();
    if (!GeminiConfig.isConfigured ||
        _autoAnalysisDone ||
        !_textReady ||
        key == _aiKey) {
      return;
    }
    _aiTimer = Timer(_aiDebounce, () => _analyze(auto: true));
  }

  /// Gemini indisponible (clé, réseau, quota…) : pas de carte, le formulaire
  /// fonctionne normalement (le détail est dans le debugPrint du service).
  Future<void> _analyze({bool auto = false}) async {
    _aiTimer?.cancel();
    if (!GeminiConfig.isConfigured) {
      debugPrint('[ComplaintAI] Gemini non configuré : pas de suggestion');
      return;
    }
    // Quota du jour atteint sur tous les modèles : aucun appel.
    if (GeminiService.quotaReached) {
      debugPrint('[ComplaintAI] Quota atteint : pas de suggestion');
      if (!auto) AppSnack.info(context, context.l10n.aiQuotaReached);
      return;
    }
    if (!_textReady) {
      _formKey.currentState?.validate();
      return;
    }
    final key = _textKey;
    if (key == _aiKey || _aiAnalyzing) return;

    setState(() => _aiAnalyzing = true);
    if (auto) _autoAnalysisDone = true;
    final result = await _gemini.analyzeComplaint(
      title: _title.text,
      description: _description.text,
    );
    if (!mounted) return;
    setState(() {
      _aiAnalyzing = false;
      if (result == null) return;
      _ai = result;
      _aiKey = key;
      _aiDecided = false;
    });
    if (result == null) {
      debugPrint('[ComplaintAI] Pas de suggestion, formulaire inchangé');
      if (!auto && GeminiService.quotaReached && mounted) {
        AppSnack.info(context, context.l10n.aiQuotaReached);
      }
    }
  }

  void _acceptAi() {
    final ai = _ai;
    if (ai == null) return;
    _selectCategory(ai.category);
    setState(() {
      _priority = ai.suggestedPriority;
      _aiDecided = true;
    });
    AppSnack.success(context, context.l10n.aiApplied);
  }

  void _keepChoice() {
    setState(() => _aiDecided = true);
    AppSnack.info(context, context.l10n.aiKept);
  }

  void _selectCategory(ComplaintCategory c) {
    setState(() {
      _category = c;
      _showCategoryError = false;
      // Enchère : on propose directement de lier une enchère.
      if (c == ComplaintCategory.enchere && _link == _LinkType.none) {
        _link = _LinkType.auction;
      }
    });
    // Panne : position jointe automatiquement (sauf si l'utilisateur a déjà
    // choisi lui-même).
    if (c == ComplaintCategory.panne && !_locationTouched && !_attachLocation) {
      _setAttachLocation(true);
    }
  }

  /// Active / désactive la position. GPS refusé ou coupé → interrupteur
  /// remis à « non » et message : la réclamation part sans position.
  void _setAttachLocation(bool on) {
    setState(() {
      _attachLocation = on;
      _locationFailure = null;
      if (!on) {
        _location = null;
        _locating = null;
      }
    });
    if (!on || _location != null) return;

    final future = const LocationService()
        .detect()
        .then<DetectedLocation?>((d) => d)
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _locationFailure = e is LocationException
                  ? e.reason
                  : LocationFailure.unknown;
              _attachLocation = false;
            });
          }
          return null;
        });
    _locating = future;
    future.then((d) {
      if (mounted && identical(_locating, future)) {
        setState(() {
          _location = d;
          _locating = null;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _store = context.read<ComplaintProvider>().photoStore;

    if (_isEdit) {
      final c = context.read<ComplaintProvider>().byId(widget.complaintId!);
      _editing = c;
      if (c != null) {
        _photos = [...c.photoPaths];
        if (c.hasLocation) {
          _attachLocation = true;
          _locationTouched = true;
          _location = DetectedLocation(
            latitude: c.latitude!,
            longitude: c.longitude!,
            nearestCity: c.agency ?? '',
            distanceKm: 0,
            address: c.locationAddress,
          );
        }
        _category = c.category;
        _priority = c.priority;
        _title.text = c.title;
        _description.text = c.description;
        if (c.reservationId != null) {
          _link = _LinkType.reservation;
          _reservationId = c.reservationId;
        } else if (c.auctionId != null) {
          _link = _LinkType.auction;
          _auctionId = c.auctionId;
        }
      }
    } else if (widget.reservationId != null) {
      _link = _LinkType.reservation;
      _reservationId = widget.reservationId;
    }

    final draft = widget.draft;
    if (!_isEdit && draft != null) {
      _category = draft.category;
      _priority = draft.effectivePriority;
      _title.text = draft.title;
      _description.text = draft.description;
      if (draft.reservationId != null) {
        _link = _LinkType.reservation;
        _reservationId = draft.reservationId;
      }
      // Panne : position jointe comme avec la grille de catégories.
      if (draft.category == ComplaintCategory.panne) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_locationTouched) _setAttachLocation(true);
        });
      }
    }

    _lastKey = _textKey;
    _title.addListener(_onTextChanged);
    _description.addListener(_onTextChanged);

    // Listes à lier (sans effet si déjà chargées).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReservationProvider>().load();
      context.read<AuctionProvider>().load();
    });
  }

  @override
  void dispose() {
    // Formulaire quitté sans envoyer : pas de fichiers orphelins.
    if (!_photosCommitted && _addedNow.isNotEmpty) _store.delete(_addedNow);
    _aiTimer?.cancel();
    _gemini.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photos
  // ---------------------------------------------------------------------------

  Future<void> _addPhoto() async {
    final l = context.l10n;
    if (_photos.length >= _maxPhotos) {
      AppSnack.info(context, l.complaintPhotoMax);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.accent,
              ),
              title: Text(l.scanCamera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.accent,
              ),
              title: Text(l.scanGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _addingPhoto = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (file == null) return; // annulé
      final saved = await _store.save(file);
      if (!mounted) return;
      setState(() {
        _photos = [..._photos, saved];
        _addedNow.add(saved);
      });
    } on PlatformException catch (e) {
      debugPrint('[ComplaintPhotos] image_picker : ${e.code} ${e.message}');
      if (mounted) {
        AppSnack.error(
          context,
          e.code == 'camera_access_denied'
              ? l.scanCameraDenied
              : l.complaintPhotoFailed,
        );
      }
    } catch (e) {
      debugPrint('[ComplaintPhotos] Ajout impossible : $e');
      if (mounted) AppSnack.error(context, l.complaintPhotoFailed);
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  void _removePhoto(String path) {
    setState(() => _photos = _photos.where((p) => p != path).toList());
    if (_addedNow.remove(path)) {
      _store.delete([path]); // ajoutée à l'instant : fichier inutile
    } else {
      _removedOriginals.add(path); // supprimée après l'enregistrement
    }
  }

  /// Réservations liables : toutes sauf annulées, les plus récentes d'abord.
  List<Reservation> _reservations(ReservationProvider p) =>
      p.reservations
          .where((r) => r.status != ReservationStatus.annulee)
          .toList()
        ..sort((a, b) => b.range.start.compareTo(a.range.start));

  /// Enchères auxquelles l'utilisateur a participé.
  List<Auction> _auctions(AuctionProvider p) =>
      p.auctions.where((a) => a.userHasBid).toList();

  Reservation? _selectedReservation(ReservationProvider p) {
    for (final r in p.reservations) {
      if (r.id == _reservationId) return r;
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final linkMissing =
        (_link == _LinkType.reservation && _reservationId == null) ||
        (_link == _LinkType.auction && _auctionId == null);
    setState(() {
      _showCategoryError = _category == null;
      _showLinkError = linkMissing;
      _saveFailed = false;
    });
    final fieldsOk = _formKey.currentState!.validate();
    if (!fieldsOk || _category == null || linkMissing) return;

    final provider = context.read<ComplaintProvider>();
    final reservation = _link == _LinkType.reservation
        ? _selectedReservation(context.read<ReservationProvider>())
        : null;
    final auctionId = _link == _LinkType.auction ? _auctionId : null;

    setState(() => _saving = true);

    // Position en cours de recherche : on l'attend (15 s maximum).
    final pending = _locating;
    if (_attachLocation && pending != null) await pending;
    if (!mounted) return;
    final location = _attachLocation ? _location : null;
    final ai = _freshAi;

    if (_isEdit) {
      final original = _editing!;
      // Texte inchangé → on garde l'analyse d'origine ; modifié sans
      // nouvelle analyse → l'ancienne n'est plus valable.
      final textUnchanged =
          _title.text.trim() == original.title &&
          _description.text.trim() == original.description;
      final updated = Complaint(
        id: original.id,
        reference: original.reference,
        userId: original.userId,
        category: _category!,
        title: _title.text.trim(),
        description: _description.text.trim(),
        priority: _priority,
        status: original.status,
        reservationId: reservation?.id,
        auctionId: auctionId,
        carLabel: reservation?.car.fullName ?? original.carLabel,
        agency: reservation?.pickupCity ?? original.agency,
        photoPaths: _photos,
        latitude: location?.latitude,
        longitude: location?.longitude,
        locationAddress: location?.address,
        aiSummary: ai?.summary ?? (textUnchanged ? original.aiSummary : null),
        aiTone: ai?.tone ?? (textUnchanged ? original.aiTone : null),
        isUrgent: _priority == ComplaintPriority.urgente,
        agencyResponse: original.agencyResponse,
        history: original.history,
        rating: original.rating,
        ratingComment: original.ratingComment,
        abusive: original.abusive,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      ).withEvent(ComplaintStatus.enAttente, 'Réclamation modifiée');
      final ok = await provider.update(updated);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = !ok;
      });
      if (ok) {
        _photosCommitted = true;
        await _store.delete(_removedOriginals);
        if (!mounted) return;
        AppSnack.success(context, context.l10n.complaintUpdated);
        context.pop();
      }
      return;
    }

    // « Avant d'envoyer, avez-vous essayé ? » (jamais bloquant).
    final proceed = await _confirmAfterQuickFixes();
    if (!mounted) return;
    if (!proceed) {
      setState(() => _saving = false);
      return;
    }

    final created = await provider.create(
      category: _category!,
      title: _title.text,
      description: _description.text,
      priority: _priority,
      reservationId: reservation?.id,
      auctionId: auctionId,
      carLabel: reservation?.car.fullName,
      agency: reservation?.pickupCity ?? location?.nearestCity,
      photoPaths: _photos,
      latitude: location?.latitude,
      longitude: location?.longitude,
      locationAddress: location?.address,
      aiSummary: ai?.summary,
      aiTone: ai?.tone,
    );
    if (created != null) _photosCommitted = true;
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    setState(() {
      _saving = false;
      _saveFailed = created == null;
      _created = created;
      // Confirmation par e-mail en arrière-plan : l'écran s'affiche tout de
      // suite, le résultat apparaît dessous quand il arrive.
      if (created != null) _mail = sendComplaintMail(created, user);
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.watch<AuthProvider>().user;

    final Widget body;
    if (user == null) {
      body = EmptyState(
        icon: Icons.lock_outline_rounded,
        title: l.complaintReport,
        message: l.complaintLoginRequired,
        actionLabel: l.commonLogin,
        onAction: () => context.go(Routes.login),
      );
    } else if (_isEdit && _editing == null) {
      body = EmptyState(
        icon: Icons.search_off_rounded,
        title: l.complaintEditTitle,
        message: l.complaintNotFound,
      );
    } else if (_isEdit && !_editing!.canEdit) {
      body = EmptyState(
        icon: Icons.lock_clock_outlined,
        title: l.complaintEditTitle,
        message: l.complaintNotEditable,
      );
    } else if (_created != null) {
      body = _SuccessView(
        complaint: _created!,
        mail: _mail,
        maskedEmail: maskedComplaintEmail(user),
      );
    } else {
      body = _form(l);
    }

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        title: Text(_isEdit ? l.complaintEditTitle : l.complaintNewTitle),
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _form(AppLocalizations l) {
    final reservations = context.watch<ReservationProvider>();
    final auctions = context.watch<AuctionProvider>();

    return ContentContainer(
      maxWidth: 720,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            16,
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            28,
          ),
          children: [
            Text(
              l.complaintFormSubtitle,
              style: TextStyle(
                fontSize: 13.5,
                color: context.cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            // Plus de 3 rejets en 30 jours : avertissement avant la création.
            if (!_isEdit) ..._rejectionWarning(l),

            // --- Catégorie ---
            _SectionTitle(l.complaintCategoryLabel),
            _CategoryGrid(selected: _category, onSelected: _selectCategory),
            if (_showCategoryError) _ErrorText(l.complaintCategoryRequired),
            const SizedBox(height: 22),

            // --- Lien réservation / enchère ---
            _SectionTitle(l.complaintLinkLabel),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_LinkType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _LinkType.none,
                    label: Text(l.complaintLinkNone),
                  ),
                  ButtonSegment(
                    value: _LinkType.reservation,
                    icon: const Icon(Icons.event_note_rounded, size: 18),
                    label: Text(l.complaintLinkReservation),
                  ),
                  ButtonSegment(
                    value: _LinkType.auction,
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: Text(l.complaintLinkAuction),
                  ),
                ],
                selected: {_link},
                onSelectionChanged: (s) => setState(() {
                  _link = s.first;
                  _showLinkError = false;
                }),
              ),
            ),
            const SizedBox(height: 12),
            ..._linkChoices(l, reservations, auctions),
            if (_showLinkError)
              _ErrorText(
                _link == _LinkType.reservation
                    ? l.complaintPickReservation
                    : l.complaintPickAuction,
              ),
            const SizedBox(height: 22),

            // --- Titre et description ---
            TextFormField(
              controller: _title,
              maxLength: _titleMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.complaintTitleLabel,
                hintText: l.complaintTitleHint,
                prefixIcon: const Icon(Icons.title_rounded),
              ),
              validator: (v) {
                final n = v?.trim().length ?? 0;
                return (n < _titleMin || n > _titleMax)
                    ? l.complaintTitleLength
                    : null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              maxLength: _descMax,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              minLines: 5,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.complaintDescLabel,
                hintText: l.complaintDescHint,
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final n = v?.trim().length ?? 0;
                return (n < _descMin || n > _descMax)
                    ? l.complaintDescLength
                    : null;
              },
            ),

            // --- Suggestion IA (masquée si Gemini n'est pas configuré) ---
            if (GeminiConfig.isConfigured) ...[
              Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _improving ? null : _improveText,
                    icon: _improving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_note_rounded, size: 20),
                    label: Text(_improving ? l.aiImproving : l.aiImprove),
                  ),
                  if (!_aiAnalyzing &&
                      (_ai == null || _aiDecided) &&
                      _freshAi == null)
                    TextButton.icon(
                      onPressed: _analyze,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(l.aiAnalyze),
                    ),
                ],
              ),
              if (_aiAnalyzing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l.aiAnalyzing,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_ai != null && !_aiDecided)
                _AiSuggestionCard(
                  analysis: _ai!,
                  onAccept: _acceptAi,
                  onKeep: _keepChoice,
                ),
            ],
            const SizedBox(height: 18),

            // --- Priorité ---
            _SectionTitle(l.complaintPriorityLabel),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ComplaintPriority>(
                showSelectedIcon: false,
                segments: [
                  for (final p in ComplaintPriority.values)
                    ButtonSegment(
                      value: p,
                      icon: Icon(p.icon, size: 18, color: p.color),
                      label: Text(l.complaintPriority(p)),
                    ),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
            ),
            const SizedBox(height: 22),

            // --- Photos (preuves) ---
            Row(
              children: [
                Expanded(child: _SectionTitle(l.complaintPhotosTitle)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${_photos.length}/$_maxPhotos',
                    style: TextStyle(fontSize: 12.5, color: context.cs.outline),
                  ),
                ),
              ],
            ),
            Text(
              l.complaintPhotosHint,
              style: TextStyle(fontSize: 12.5, color: context.cs.outline),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  ComplaintPhotoThumb(
                    path: _photos[i],
                    onTap: () =>
                        openComplaintGallery(context, _photos, initialIndex: i),
                    onRemove: () => _removePhoto(_photos[i]),
                  ),
                if (_photos.length < _maxPhotos)
                  _AddPhotoTile(
                    loading: _addingPhoto,
                    label: l.complaintPhotoAdd,
                    onTap: _addingPhoto ? null : _addPhoto,
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // --- Position ---
            _LocationTile(
              attach: _attachLocation,
              locating: _locating != null,
              location: _location,
              failure: _locationFailure,
              onChanged: (v) {
                _locationTouched = true;
                _setAttachLocation(v);
              },
            ),
            const SizedBox(height: 20),

            if (_saveFailed) ...[
              NoticeBox(
                icon: Icons.error_outline_rounded,
                color: AppColors.danger,
                message: l.complaintSaveFailed,
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEdit ? Icons.save_rounded : Icons.send_rounded),
                label: Text(
                  _checkingFixes
                      ? l.quickFixChecking
                      : (_isEdit ? l.editSaveChanges : l.complaintSubmit),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Score de confiance : avertit si plus de 3 réclamations ont été rejetées
  /// ces 30 derniers jours (n'empêche pas l'envoi).
  List<Widget> _rejectionWarning(AppLocalizations l) {
    const trust = ComplaintTrustService();
    final complaints = context.watch<ComplaintProvider>().complaints;
    if (!trust.shouldWarnBeforeCreate(complaints)) return const [];
    return [
      NoticeBox(
        icon: Icons.gpp_maybe_outlined,
        color: AppColors.warning,
        title: l.complaintRejectionWarningTitle,
        message: l.complaintRejectionWarning(
          trust.recentRejections(complaints),
        ),
      ),
      const SizedBox(height: 18),
    ];
  }

  /// Liste des réservations / enchères à choisir (ou message si vide).
  List<Widget> _linkChoices(
    AppLocalizations l,
    ReservationProvider reservations,
    AuctionProvider auctions,
  ) {
    switch (_link) {
      case _LinkType.none:
        return const [];
      case _LinkType.reservation:
        final list = _reservations(reservations);
        if (list.isEmpty) {
          return [NoticeBox(message: l.complaintNoReservation)];
        }
        final selected = _selectedReservation(reservations);
        return [
          for (final r in list)
            _ChoiceTile(
              selected: r.id == _reservationId,
              icon: Icons.directions_car_rounded,
              title: r.car.fullName,
              subtitle:
                  '${r.reference} · ${context.dateLong(r.range.start)} · '
                  '${r.pickupCity}',
              onTap: () => setState(() {
                _reservationId = r.id;
                _showLinkError = false;
              }),
            ),
          if (selected != null) ...[
            const SizedBox(height: 6),
            NoticeBox(
              icon: Icons.auto_fix_high_rounded,
              color: AppColors.success,
              message: l.complaintAutoFilled(
                selected.car.fullName,
                selected.pickupCity,
              ),
            ),
          ],
        ];
      case _LinkType.auction:
        final list = _auctions(auctions);
        if (list.isEmpty) return [NoticeBox(message: l.complaintNoAuction)];
        return [
          for (final a in list)
            _ChoiceTile(
              selected: a.id == _auctionId,
              icon: Icons.gavel_rounded,
              title: a.title,
              subtitle: a.city,
              onTap: () => setState(() {
                _auctionId = a.id;
                _showLinkError = false;
              }),
            ),
        ];
    }
  }
}

// -----------------------------------------------------------------------------
// Widgets
// -----------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: context.cs.onSurface,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
      ),
    );
  }
}

/// Catégories en cartes avec icônes (3 colonnes, 2 sur petit écran).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});

  final ComplaintCategory? selected;
  final ValueChanged<ComplaintCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final columns = MediaQuery.sizeOf(context).width < 360 ? 2 : 3;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final c in ComplaintCategory.values)
          _CategoryCard(
            category: c,
            label: l.complaintCategory(c),
            selected: c == selected,
            onTap: () => onSelected(c),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ComplaintCategory category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : context.cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: selected ? color : context.cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: context.cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne sélectionnable (réservation ou enchère).
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.cs.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.10) : context.cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: selected ? accent : context.cs.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          leading: Icon(icon, color: accent),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.cs.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.cs.outline),
          ),
          trailing: Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? accent : context.cs.outline,
          ),
        ),
      ),
    );
  }
}

/// Carte « Suggestion IA » : catégorie + priorité proposées par Gemini.
/// Le client accepte ou garde son choix.
class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard({
    required this.analysis,
    required this.onAccept,
    required this.onKeep,
  });

  final ComplaintAiAnalysis analysis;
  final VoidCallback onAccept;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = context.cs.primary;
    final priority = analysis.suggestedPriority;

    Widget line(String label, IconData icon, Color color, String value) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              '$label : ',
              style: TextStyle(fontSize: 13, color: context.cs.outline),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: context.cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: AppCard(
        color: accent.withValues(alpha: 0.07),
        borderColor: accent.withValues(alpha: 0.45),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  l.aiSuggestionTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: context.cs.onSurface,
                  ),
                ),
              ],
            ),
            line(
              l.aiSuggestionCategory,
              analysis.category.icon,
              analysis.category.color,
              l.complaintCategory(analysis.category),
            ),
            line(
              l.aiSuggestionPriority,
              priority.icon,
              priority.color,
              l.complaintPriority(priority),
            ),
            line(
              l.aiToneLabel,
              analysis.tone.icon,
              analysis.tone.color,
              l.complaintTone(analysis.tone),
            ),
            if (analysis.priorityRaised) ...[
              const SizedBox(height: 8),
              NoticeBox(
                icon: Icons.trending_up_rounded,
                color: AppColors.warning,
                message: l.aiPriorityRaised,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l.aiDisclaimer,
              style: TextStyle(fontSize: 11.5, color: context.cs.outline),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(onPressed: onKeep, child: Text(l.aiKeep)),
                FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(l.aiAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Avant / après de « Améliorer mon message ». Retourne `true` si accepté.
class _ImproveSheet extends StatelessWidget {
  const _ImproveSheet({required this.before, required this.after});

  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = context.cs.primary;

    Widget block(
      String label,
      String text,
      Color color, {
      bool strong = false,
    }) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: strong
                    ? context.cs.onSurface
                    : context.cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.aiImproveTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l.aiImproveHint,
                style: TextStyle(fontSize: 12.5, color: context.cs.outline),
              ),
              const SizedBox(height: 14),
              block(l.aiBefore, before, context.cs.outline),
              const SizedBox(height: 10),
              block(l.aiAfter, after, AppColors.success, strong: true),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.aiKeepMine),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(l.aiUseImproved),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Avant d'envoyer, avez-vous essayé ? » : 1 à 3 solutions rapides.
class _QuickFixSheet extends StatelessWidget {
  const _QuickFixSheet({required this.fixes});

  final List<String> fixes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.quickFixTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.quickFixSubtitle,
              style: TextStyle(fontSize: 12.5, color: context.cs.outline),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < fixes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  color: context.cs.surface,
                  borderColor: context.cs.outlineVariant,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: context.cs.primary.withValues(
                          alpha: 0.14,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: context.cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fixes[i],
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: context.cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _QuickFixChoice.resolved),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(l.quickFixResolved),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _QuickFixChoice.sendAnyway),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(l.quickFixSendAnyway),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation après l'envoi, avec la référence REC-… .
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.complaint,
    required this.mail,
    required this.maskedEmail,
  });

  final Complaint complaint;

  /// E-mail de confirmation en cours d'envoi (non bloquant).
  final Future<ComplaintMailResult>? mail;
  final String maskedEmail;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ContentContainer(
          maxWidth: 480,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.complaintSentTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.cs.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: context.cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    Text(
                      l.complaintReferenceLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.cs.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      complaint.reference,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: context.cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (mail != null)
                _MailStatus(mail: mail!, maskedEmail: maskedEmail),
              const SizedBox(height: 14),
              Text(
                l.complaintSentMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.profile),
                  child: Text(l.complaintDone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne discrète sous la référence : envoi → envoyé / échec.
/// Rien si l'e-mail n'est pas configuré (Template ID manquant).
class _MailStatus extends StatelessWidget {
  const _MailStatus({required this.mail, required this.maskedEmail});

  final Future<ComplaintMailResult> mail;
  final String maskedEmail;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<ComplaintMailResult>(
      future: mail,
      builder: (context, snap) {
        final Widget icon;
        final String text;
        var color = context.cs.outline;
        switch (snap.data) {
          case null:
            icon = const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
            text = l.complaintMailSending;
          case ComplaintMailResult.sent:
            color = AppColors.success;
            icon = Icon(Icons.mark_email_read_outlined, size: 18, color: color);
            text = l.complaintMailSent(maskedEmail);
          case ComplaintMailResult.failed:
            icon = Icon(Icons.mail_outline_rounded, size: 18, color: color);
            text = l.complaintMailFailed;
          case ComplaintMailResult.skipped:
            return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Case « + Ajouter » de la grille de photos.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.loading,
    required this.label,
    required this.onTap,
  });

  final bool loading;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm);
    return Material(
      color: context.cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.cs.outlineVariant, width: 1.4),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          width: 84,
          height: 84,
          child: loading
              ? const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: context.cs.primary),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.cs.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Interrupteur « Joindre ma position » + adresse / état de la recherche.
class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.attach,
    required this.locating,
    required this.location,
    required this.failure,
    required this.onChanged,
  });

  final bool attach;
  final bool locating;
  final DetectedLocation? location;
  final LocationFailure? failure;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    final Widget? status;
    if (attach && locating) {
      status = Row(
        children: [
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l.commonLocating,
            style: TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant),
          ),
        ],
      );
    } else if (attach && location != null) {
      status = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location!.address ?? l.complaintLocationNoAddress,
              style: TextStyle(fontSize: 13, color: context.cs.onSurface),
            ),
          ),
        ],
      );
    } else if (failure != null) {
      // GPS refusé / coupé : on envoie sans position.
      status = NoticeBox(
        icon: Icons.location_off_rounded,
        color: AppColors.warning,
        message: '${l.locationError(failure!)}\n${l.complaintLocationOff}',
      );
    } else {
      status = null;
    }

    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 10),
      child: // Material transparent : effet d'appui visible dans la carte colorée.
      Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                Icons.my_location_rounded,
                color: context.cs.primary,
              ),
              title: Text(
                l.complaintAttachLocation,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.cs.onSurface,
                ),
              ),
              subtitle: Text(
                l.complaintAttachLocationSub,
                style: TextStyle(fontSize: 12, color: context.cs.outline),
              ),
              value: attach,
              onChanged: onChanged,
            ),
            if (status != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: status,
              ),
          ],
        ),
      ),
    );
  }
}
