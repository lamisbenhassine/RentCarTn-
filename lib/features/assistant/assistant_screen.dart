import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/services/voice_input_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/complaint.dart';
import '../../data/models/complaint_draft.dart';
import '../../data/models/reservation.dart';
import '../../data/services/assistant_prompt.dart';
import '../../data/services/assistant_tools.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_provider.dart';
import '../../state/car_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/complaint_provider.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';
import '../complaints/complaint_l10n.dart';
import '../complaints/complaint_actions.dart';
import '../complaints/complaint_mail.dart';
import '../complaints/urgent_breakdown.dart';

/// « Assistant RentCar » : chat Gemini multi-tour (pannes, réservations,
/// réclamations, permis, agences), en fr / en / ar / derja.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = -1;
  bool _lastTyping = false;

  /// Messages déjà affichés à l'ouverture : pas d'animation d'apparition.
  Set<String>? _seenIds;

  // --- Saisie vocale ---
  final _voice = VoiceInputService();
  bool _listening = false;
  VoiceLanguage? _voiceChoice;

  /// Choix du client, sinon la langue de l'app (arabe → ar-TN).
  VoiceLanguage get _voiceLanguage =>
      _voiceChoice ??
      (Localizations.localeOf(context).languageCode == 'ar'
          ? VoiceLanguage.ar
          : VoiceLanguage.fr);

  /// Micro : dictée en fr-FR / ar-TN, texte partiel dans le champ, puis
  /// envoi automatique du texte final.
  Future<void> _toggleVoice() async {
    if (_listening) {
      await _voice.stop();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _listening = true);
    final failure = await _voice.start(
      language: _voiceLanguage,
      onResult: (text, isFinal) {
        if (!mounted) return;
        _input.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        if (isFinal && text.trim().isNotEmpty) {
          setState(() => _listening = false);
          _send(text);
        }
      },
      onFailure: _showVoiceFailure,
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (failure != null) _showVoiceFailure(failure);
  }

  void _showVoiceFailure(VoiceFailure failure) {
    if (!mounted) return;
    final l = context.l10n;
    setState(() => _listening = false);
    switch (failure) {
      case VoiceFailure.permissionDenied:
        // Refus (ou « Ne plus demander ») : on explique où réactiver ;
        // le clavier reste disponible.
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.mic_off_rounded, color: AppColors.warning),
            title: Text(l.assistantMicDeniedTitle),
            content: Text(l.assistantMicDenied),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l.commonClose),
              ),
            ],
          ),
        );
      case VoiceFailure.unavailable:
        AppSnack.error(context, l.assistantVoiceUnavailable);
      case VoiceFailure.noMatch:
        AppSnack.info(context, l.assistantVoiceNoMatch);
      case VoiceFailure.error:
        AppSnack.error(context, l.assistantVoiceError);
    }
  }

  /// Texte qui s'affiche progressivement : on reste en bas si on y était.
  void _followBottom() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.maxScrollExtent - p.pixels < 160) _scroll.jumpTo(p.maxScrollExtent);
  }

  /// Soutenance : 👍 / 👎 enregistrés sur le téléphone.
  void _showQuality() {
    final l = context.l10n;
    final stats = context.read<ChatProvider>().feedbackStats;
    final total = stats.up + stats.down;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.insights_rounded),
        title: Text(l.assistantQuality),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total == 0
                  ? l.assistantQualityEmpty
                  : l.assistantQualityStats(
                      stats.up,
                      stats.down,
                      (stats.up * 100 / total).round(),
                    ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stats.up / total,
                  minHeight: 10,
                  color: AppColors.success,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l.assistantQualityNote,
              style: TextStyle(fontSize: 12, color: context.cs.outline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Contexte du client (réservation en cours) : sans effet si déjà chargé.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReservationProvider>().load();
      context.read<CarProvider>().load(); // véhicules du client (catalogue)
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _voice.cancel();
    super.dispose();
  }

  Reservation? _reservation() => currentOrNextReservation(
    context.read<ReservationProvider>().reservations,
  );

  /// Contexte du client : prénom / ville dans l'instruction système,
  /// réservation et réclamations lues par les fonctions de l'assistant.
  AssistantContext _context() {
    final user = context.read<AuthProvider>().user;
    return AssistantContext(
      firstName: user?.firstName,
      city: user?.city,
      reservation: _reservation(),
      vehicles: clientVehicles(
        context.read<ReservationProvider>().reservations,
        context.read<CarProvider>().carById,
      ),
      complaints: context.read<ComplaintProvider>().complaints,
      appLanguage: Localizations.localeOf(context).languageCode,
    );
  }

  Future<void> _send(String text) async {
    final l = context.l10n;
    if (text.trim().isEmpty) return;
    _input.clear();
    await context.read<ChatProvider>().send(
      text,
      context: _context(),
      strings: ChatStrings(
        offline: l.assistantOffline,
        unavailable: l.assistantUnavailable,
        quota: l.aiQuotaReached,
        draftIntro: l.assistantDraftIntro,
      ),
    );
  }

  /// [Confirmer] : même création que le formulaire (référence REC-…,
  /// notifications via ComplaintProvider, e-mail de confirmation).
  Future<void> _confirmDraft(ChatMessage message) async {
    final l = context.l10n;
    final complaints = context.read<ComplaintProvider>();
    final reservations = context.read<ReservationProvider>();
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      AppSnack.info(context, l.complaintLoginRequired);
      return;
    }
    // Panne / propreté sans véhicule (aucun dans ses réservations) : le
    // client le choisit dans le formulaire, rien n'est inventé.
    final pending = message.draft;
    if (pending != null &&
        pending.category.requiresCar &&
        pending.carId == null) {
      AppSnack.info(context, l.assistantPickCar);
      _editDraft(message);
      return;
    }
    final cars = context.read<CarProvider>();

    final created = await context.read<ChatProvider>().confirmDraft(
      message.id,
      create: (draft) {
        Reservation? linked;
        for (final r in reservations.reservations) {
          if (r.id == draft.reservationId) linked = r;
        }
        return complaints.create(
          category: draft.category,
          title: draft.title,
          description: draft.description,
          priority: draft.effectivePriority,
          reservationId: linked?.id,
          carId: draft.carId,
          carLabel: draft.carId == null
              ? null
              : (cars.carById(draft.carId!)?.title ?? draft.carLabel),
          agency: linked?.pickupCity,
        );
      },
      createdText: (c) => l.assistantComplaintCreated(c.reference),
    );
    if (!mounted) return;
    if (created == null) {
      AppSnack.error(context, l.complaintSaveFailed);
      return;
    }
    // E-mail en arrière-plan : un échec ne change rien à la réclamation.
    sendComplaintMail(created, user);
  }

  /// [Modifier] : formulaire classique pré-rempli avec la proposition.
  void _editDraft(ChatMessage message) {
    final draft = message.draft;
    if (draft == null) return;
    context.read<ChatProvider>().markDraftEdited(message.id);
    context.push(Routes.complaintNew, extra: draft);
  }

  Future<void> _newConversation() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.add_comment_outlined),
        title: Text(l.assistantNewConversation),
        content: Text(l.assistantNewConversationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.assistantClear),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ChatProvider>().newConversation();
    }
  }

  void _openAction(ChatMessage message, ChatAction action) {
    switch (action) {
      case ChatAction.newComplaint:
        context.push(Routes.complaintNew);
      case ChatAction.urgentBreakdown:
        final r = _reservation();
        showUrgentBreakdownSheet(
          context,
          reservationId: r?.status == ReservationStatus.enCours ? r!.id : null,
        );
      case ChatAction.myReservations:
        context.push(Routes.reservations);
      case ChatAction.myComplaints:
        context.push(Routes.complaints);
      case ChatAction.viewComplaint:
        final id = message.complaintId;
        context.push(id == null ? Routes.complaints : Routes.complaint(id));
      case ChatAction.callAgency:
        callAgency(context);
    }
  }

  /// Nouveau message ou « écrit… » : défilement jusqu'en bas.
  void _autoScroll(int count, bool typing) {
    if (count == _lastCount && typing == _lastTyping) return;
    final animate = _lastCount != -1;
    _lastCount = count;
    _lastTyping = typing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chat = context.watch<ChatProvider>();
    final user = context.watch<AuthProvider>().user;
    final messages = chat.messages;
    _seenIds ??= {for (final m in messages) m.id};
    _autoScroll(messages.length, chat.isTyping);

    final chips = [
      (
        Icons.car_crash_outlined,
        l.assistantChipBreakdown,
        l.assistantChipBreakdownMsg,
      ),
      (
        Icons.event_note_rounded,
        l.assistantChipReservation,
        l.assistantChipReservationMsg,
      ),
      (
        Icons.support_agent_rounded,
        l.assistantChipComplaint,
        l.assistantChipComplaintMsg,
      ),
    ];

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        titleSpacing: 0,
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
        title: Row(
          children: [
            const _AssistantAvatar(size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.assistantTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    chat.isTyping ? l.assistantTyping : l.assistantSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: chat.isTyping
                          ? AppColors.success
                          : context.cs.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.assistantNewConversation,
            onPressed: messages.isEmpty || chat.isTyping
                ? null
                : _newConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: l.assistantQuality,
            onPressed: _showQuality,
            icon: const Icon(Icons.insights_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 760,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  children: [
                    // Accueil (non enregistré dans l'historique).
                    _Bubble(
                      message: ChatMessage(
                        id: 'welcome',
                        role: ChatRole.assistant,
                        text: user == null
                            ? l.assistantWelcomeGuest
                            : l.assistantWelcome(user.firstName),
                        date: DateTime.now(),
                      ),
                      showTime: false,
                      onAction: _openAction,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 44,
                        bottom: 14,
                      ),
                      child: Text(
                        l.assistantDisclaimer,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.cs.outline,
                        ),
                      ),
                    ),
                    for (final m in messages)
                      _Bubble(
                        key: ValueKey(m.id),
                        message: m,
                        onAction: _openAction,
                        onConfirm: _confirmDraft,
                        onEdit: _editDraft,
                        confirming: chat.isConfirming(m.id),
                        // Seules les réponses arrivées écran ouvert s'animent.
                        animate:
                            _seenIds!.add(m.id) &&
                            !m.isUser &&
                            DateTime.now().difference(m.date).inSeconds < 30,
                        onRevealProgress: _followBottom,
                        onFeedback: (liked) => context
                            .read<ChatProvider>()
                            .setFeedback(m.id, liked),
                      ),
                    if (chat.isTyping) const _TypingIndicator(),
                  ],
                ),
              ),

              // Suggestions rapides.
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  itemCount: chips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(
                    avatar: Icon(chips[i].$1, size: 18),
                    label: Text(chips[i].$2),
                    onPressed: chat.isTyping ? null : () => _send(chips[i].$3),
                  ),
                ),
              ),

              // Dictée : langue (fr-FR / ar-TN) + « Je vous écoute… ».
              _VoiceBar(
                listening: _listening,
                language: _voiceLanguage,
                onLanguage: (v) => setState(() => _voiceChoice = v),
              ),

              // Saisie.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: chat.isTyping ? null : _send,
                        decoration: InputDecoration(
                          hintText: l.assistantHint,
                          counterText: '',
                          filled: true,
                          fillColor: context.cs.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: context.cs.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: context.cs.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Champ vide → micro ; texte saisi → envoyer.
                    ListenableBuilder(
                      listenable: _input,
                      builder: (context, _) {
                        final hasText = _input.text.trim().isNotEmpty;
                        if (hasText && !_listening) {
                          return IconButton.filled(
                            tooltip: l.assistantSend,
                            onPressed: chat.isTyping
                                ? null
                                : () => _send(_input.text),
                            icon: const Icon(Icons.send_rounded),
                          );
                        }
                        return IconButton.filled(
                          tooltip: _listening
                              ? l.assistantStopListening
                              : l.assistantMic,
                          style: _listening
                              ? IconButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                )
                              : null,
                          onPressed: chat.isTyping ? null : _toggleVoice,
                          icon: Icon(
                            _listening ? Icons.stop_rounded : Icons.mic_rounded,
                          ),
                        );
                      },
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

// -----------------------------------------------------------------------------
// Widgets
// -----------------------------------------------------------------------------

/// Avatar rond de l'assistant (dégradé de l'app).
class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        gradient: AppColors.accentGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}

/// Bulle de message. Le texte en arabe s'affiche de droite à gauche, quelle
/// que soit la langue de l'application.
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.onAction,
    this.onConfirm,
    this.onEdit,
    this.confirming = false,
    this.showTime = true,
    this.animate = false,
    this.onRevealProgress,
    this.onFeedback,
  });

  final ChatMessage message;
  final void Function(ChatMessage message, ChatAction action) onAction;

  /// Nouvelle réponse : texte révélé progressivement.
  final bool animate;
  final VoidCallback? onRevealProgress;

  /// 👍 `true` / 👎 `false`.
  final ValueChanged<bool>? onFeedback;

  /// Carte « réclamation proposée » : [Confirmer] / [Modifier].
  final ValueChanged<ChatMessage>? onConfirm;
  final ValueChanged<ChatMessage>? onEdit;
  final bool confirming;
  final bool showTime;

  String _actionLabel(AppLocalizations l, ChatAction a) => switch (a) {
    ChatAction.newComplaint => l.assistantActionComplaint,
    ChatAction.urgentBreakdown => l.assistantActionBreakdown,
    ChatAction.myReservations => l.assistantActionReservations,
    ChatAction.myComplaints => l.assistantActionComplaints,
    ChatAction.viewComplaint => l.assistantActionViewComplaint,
    ChatAction.callAgency => l.assistantActionCallAgency,
  };

  IconData _actionIcon(ChatAction a) => switch (a) {
    ChatAction.newComplaint => Icons.report_problem_outlined,
    ChatAction.urgentBreakdown => Icons.car_crash_rounded,
    ChatAction.myReservations => Icons.event_note_rounded,
    ChatAction.myComplaints => Icons.support_agent_rounded,
    ChatAction.viewComplaint => Icons.open_in_new_rounded,
    ChatAction.callAgency => Icons.call_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mine = message.isUser;
    final primary = context.cs.primary;
    final rtl = isArabicText(message.text);

    final bubbleColor = mine
        ? primary
        : message.isError
        ? AppColors.warning.withValues(alpha: 0.12)
        : context.cs.surface;
    final textColor = mine ? Colors.white : context.cs.onSurface;
    const r = Radius.circular(18);
    const tail = Radius.circular(4);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadiusDirectional.only(
          topStart: mine ? r : tail,
          topEnd: mine ? tail : r,
          bottomStart: r,
          bottomEnd: r,
        ),
        border: mine
            ? null
            : Border.all(
                color: message.isError
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : context.cs.outlineVariant,
              ),
      ),
      child: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isError) ...[
              const Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: _RevealText(
                text: message.text,
                animate: animate,
                onProgress: onRevealProgress,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: mine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                const _AssistantAvatar(size: 32),
                const SizedBox(width: 8),
              ],
              Flexible(child: bubble),
            ],
          ),
          if (message.draft != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 40, top: 8),
              child: _DraftCard(
                draft: message.draft!,
                state: message.draftState,
                confirming: confirming,
                onConfirm: onConfirm == null ? null : () => onConfirm!(message),
                onEdit: onEdit == null ? null : () => onEdit!(message),
              ),
            ),
          if (message.actions.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 40, top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final a in message.actions)
                    OutlinedButton.icon(
                      onPressed: () => onAction(message, a),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: a == ChatAction.urgentBreakdown
                            ? AppColors.danger
                            : primary,
                        side: BorderSide(
                          color: a == ChatAction.urgentBreakdown
                              ? AppColors.danger
                              : primary,
                        ),
                      ),
                      icon: Icon(_actionIcon(a), size: 18),
                      label: Text(_actionLabel(l, a)),
                    ),
                ],
              ),
            ),
          if (showTime)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: mine ? 0 : 42,
                end: mine ? 4 : 0,
                top: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.Hm().format(message.date),
                    style: TextStyle(fontSize: 10.5, color: context.cs.outline),
                  ),
                  // 👍 / 👎 sur les réponses de l'assistant (pas les erreurs).
                  if (onFeedback != null && !mine && !message.isError) ...[
                    const SizedBox(width: 6),
                    _ThumbButton(
                      up: true,
                      selected: message.liked == true,
                      tooltip: l.assistantFeedbackUp,
                      onTap: () => onFeedback!(true),
                    ),
                    _ThumbButton(
                      up: false,
                      selected: message.liked == false,
                      tooltip: l.assistantFeedbackDown,
                      onTap: () => onFeedback!(false),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// « écrit… » : trois points qui rebondissent l'un après l'autre.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dotColor = context.cs.outline;
    return Semantics(
      label: '${l.assistantTitle} ${l.assistantTyping}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _AssistantAvatar(size: 32),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.cs.surface,
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(4),
                  topEnd: Radius.circular(18),
                  bottomStart: Radius.circular(18),
                  bottomEnd: Radius.circular(18),
                ),
                border: Border.all(color: context.cs.outlineVariant),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      _dot(i, dotColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chaque point monte puis redescend, décalé de 0,2 s.
  Widget _dot(int i, Color color) {
    final t = (_controller.value - i * 0.18) % 1.0;
    final up = t < 0.3
        ? Curves.easeOut.transform(t / 0.3)
        : t < 0.6
        ? 1 - Curves.easeIn.transform((t - 0.3) / 0.3)
        : 0.0;
    return Transform.translate(
      offset: Offset(0, -5 * up),
      child: Container(
        height: 8,
        width: 8,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5 + 0.5 * up),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Bouton flottant « Assistant RentCar » (accueil, Mes réclamations).
class AssistantFab extends StatelessWidget {
  const AssistantFab({super.key, this.heroTag = 'assistant-fab'});

  /// Plusieurs FAB sur un même écran : tags distincts.
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: context.l10n.assistantTitle,
      backgroundColor: Colors.transparent,
      elevation: 3,
      shape: const CircleBorder(),
      onPressed: () => context.push(Routes.assistant),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
        ),
        child: const SizedBox.expand(
          child: Icon(Icons.smart_toy_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

/// Réclamation proposée par l'assistant : rien n'est créé tant que le
/// client n'a pas appuyé sur [Confirmer].
class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.state,
    required this.confirming,
    required this.onConfirm,
    required this.onEdit,
  });

  final ComplaintDraft draft;
  final DraftState state;
  final bool confirming;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final priority = draft.effectivePriority;
    final pending = state == DraftState.pending;

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: context.cs.outline),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );

    final strong = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: context.cs.onSurface,
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: pending
              ? context.cs.primary.withValues(alpha: 0.6)
              : context.cs.outlineVariant,
          width: pending ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: context.cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.assistantDraftTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: context.cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          row(
            l.complaintCategoryLabel,
            Row(
              children: [
                Icon(
                  draft.category.icon,
                  size: 16,
                  color: draft.category.color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l.complaintCategory(draft.category),
                    style: strong,
                  ),
                ),
              ],
            ),
          ),
          row(
            l.complaintPriorityLabel,
            Row(
              children: [
                Icon(priority.icon, size: 16, color: priority.color),
                const SizedBox(width: 6),
                Text(
                  l.complaintPriority(priority),
                  style: strong.copyWith(color: priority.color),
                ),
              ],
            ),
          ),
          row(l.complaintTitleLabel, Text(draft.title, style: strong)),
          row(
            l.complaintDescLabel,
            Text(
              draft.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ),
          row(
            l.complaintCarLabel,
            Text(
              draft.carLabel ?? l.complaintCarPick,
              style: draft.carLabel == null
                  ? TextStyle(fontSize: 13, color: context.cs.outline)
                  : strong,
            ),
          ),
          row(
            l.assistantDraftReservation,
            Text(
              draft.reservationLabel ?? l.complaintLinkNone,
              style: TextStyle(fontSize: 13, color: context.cs.onSurface),
            ),
          ),
          const SizedBox(height: 12),
          switch (state) {
            DraftState.pending => Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: confirming ? null : onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(l.assistantDraftEdit),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: confirming ? null : onConfirm,
                    icon: confirming
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(l.assistantDraftConfirm),
                  ),
                ),
              ],
            ),
            DraftState.confirmed => _DraftStatus(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              text: l.assistantDraftConfirmed,
            ),
            DraftState.edited => _DraftStatus(
              icon: Icons.edit_note_rounded,
              color: context.cs.outline,
              text: l.assistantDraftEdited,
            ),
          },
          if (pending) ...[
            const SizedBox(height: 8),
            Text(
              l.assistantDraftNotice,
              style: TextStyle(fontSize: 11.5, color: context.cs.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftStatus extends StatelessWidget {
  const _DraftStatus({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Texte d'une nouvelle réponse révélé progressivement (effet « frappe »),
/// puis sélectionnable. Un appui affiche tout de suite la fin.
///
/// Pourquoi pas streamGenerateContent ? Avec le function calling, chaque
/// tour peut être un appel de fonction et les modèles Gemini 3 joignent une
/// thoughtSignature à renvoyer à l'identique : recoller des morceaux SSE
/// rendrait ce flux fragile. La réponse arrive en ~3 s, l'animation donne
/// le même ressenti sans risque.
class _RevealText extends StatefulWidget {
  const _RevealText({
    required this.text,
    required this.style,
    required this.animate,
    this.onProgress,
  });

  final String text;
  final TextStyle style;
  final bool animate;

  /// Le texte grandit : l'écran suit le bas de la conversation.
  final VoidCallback? onProgress;

  @override
  State<_RevealText> createState() => _RevealTextState();
}

class _RevealTextState extends State<_RevealText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    final length = widget.text.characters.length;
    if (!widget.animate || length == 0) return;
    // ~15 ms par caractère, entre 0,4 s et 2,5 s.
    final ms = (length * 15).clamp(400, 2500);
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: ms),
          )
          ..addListener(() {
            final next = (length * _controller!.value).ceil();
            if (next != _shown) {
              setState(() => _shown = next);
              widget.onProgress?.call();
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool get _done => _controller == null || _controller!.isCompleted;

  @override
  Widget build(BuildContext context) {
    if (_done) return SelectableText(widget.text, style: widget.style);
    final chars = widget.text.characters;
    return GestureDetector(
      onTap: () => _controller!.value = 1,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: chars.take(_shown).toString()),
            // Reste invisible : la bulle a déjà sa taille finale, pas de saut.
            TextSpan(
              text: chars.skip(_shown).toString(),
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
        style: widget.style,
      ),
    );
  }
}

/// Petit pouce 👍 / 👎 (rempli si choisi).
class _ThumbButton extends StatelessWidget {
  const _ThumbButton({
    required this.up,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final bool up;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? (up ? AppColors.success : AppColors.danger)
        : context.cs.outline;
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                up
                    ? (selected
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_alt_outlined)
                    : (selected
                          ? Icons.thumb_down_alt_rounded
                          : Icons.thumb_down_alt_outlined),
                size: 16,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre de dictée : choix de la langue (toujours visible, discret) et
/// micro qui pulse pendant l'écoute.
class _VoiceBar extends StatelessWidget {
  const _VoiceBar({
    required this.listening,
    required this.language,
    required this.onLanguage,
  });

  final bool listening;
  final VoiceLanguage language;
  final ValueChanged<VoiceLanguage> onLanguage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          if (listening) ...[
            const _PulsingMic(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.assistantListening,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ),
          ] else
            const Spacer(),
          Tooltip(
            message: l.assistantVoiceLang,
            child: SegmentedButton<VoiceLanguage>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                ButtonSegment(
                  value: VoiceLanguage.fr,
                  tooltip: l.assistantVoiceFr,
                  label: const Text('FR'),
                ),
                ButtonSegment(
                  value: VoiceLanguage.ar,
                  tooltip: l.assistantVoiceAr,
                  label: const Text('ع'),
                ),
              ],
              selected: {language},
              onSelectionChanged: listening ? null : (s) => onLanguage(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingMic extends StatefulWidget {
  const _PulsingMic();

  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.85,
        end: 1.2,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: const Icon(Icons.mic_rounded, color: AppColors.danger, size: 20),
    );
  }
}
