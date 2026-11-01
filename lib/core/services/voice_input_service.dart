import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Langue de la dictée (choisie dans l'assistant).
enum VoiceLanguage { fr, ar }

/// Pourquoi la dictée n'a pas pu démarrer ou a échoué.
enum VoiceFailure {
  /// Micro refusé (Android : RECORD_AUDIO).
  permissionDenied,

  /// Pas de service de reconnaissance sur l'appareil.
  unavailable,

  /// Rien de compris.
  noMatch,

  /// Autre erreur (réseau du service Google, etc.).
  error,
}

/// Saisie vocale (speech_to_text) : fr-FR ou ar-TN.
///
/// Une seule instance : speech_to_text ne s'initialise qu'une fois, les
/// erreurs asynchrones sont redirigées vers la dictée en cours.
class VoiceInputService {
  VoiceInputService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  List<String>? _locales;
  void Function(VoiceFailure failure)? _onFailure;
  VoidCallback? _onDone;

  bool get isListening => _speech.isListening;

  /// Démarre la dictée. [onResult] reçoit le texte partiel puis final.
  /// Retourne l'échec immédiat (permission, service absent), sinon `null`.
  Future<VoiceFailure?> start({
    required VoiceLanguage language,
    required void Function(String text, bool isFinal) onResult,
    required void Function(VoiceFailure failure) onFailure,
    required VoidCallback onDone,
  }) async {
    _onFailure = onFailure;
    _onDone = onDone;
    try {
      // Android affiche la demande RECORD_AUDIO au premier appel ; après un
      // refus, initialize() renvoie false et on peut redemander plus tard.
      final ready = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      if (!ready) {
        final allowed = await _speech.hasPermission;
        debugPrint(
          '[Voice] Initialisation impossible '
          '(${allowed ? 'service absent' : 'micro refusé'})',
        );
        return allowed ? VoiceFailure.unavailable : VoiceFailure.permissionDenied;
      }

      _locales ??= [for (final l in await _speech.locales()) l.localeId];
      final localeId = pickLocale(_locales!, language);
      debugPrint('[Voice] Dictée en ${localeId ?? 'langue du système'}');

      await _speech.listen(
        onResult: (SpeechRecognitionResult r) =>
            onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return null;
    } catch (e) {
      debugPrint('[Voice] Dictée impossible : $e');
      return VoiceFailure.unavailable;
    }
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() async {
    _onFailure = null;
    _onDone = null;
    await _speech.cancel();
  }

  void _handleError(SpeechRecognitionError e) {
    debugPrint('[Voice] Erreur ${e.errorMsg} (permanent=${e.permanent})');
    final failure = switch (e.errorMsg) {
      'error_permission' || 'error_insufficient_permissions' =>
        VoiceFailure.permissionDenied,
      'error_no_match' || 'error_speech_timeout' => VoiceFailure.noMatch,
      _ => VoiceFailure.error,
    };
    _onFailure?.call(failure);
    _finish();
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _finish();
    }
  }

  void _finish() {
    final done = _onDone;
    _onDone = null;
    done?.call();
  }

  /// Meilleure langue disponible : fr_FR / ar_TN, sinon une autre variante
  /// (fr_*, ar_*), sinon `null` = langue du système. Fonction pure.
  static String? pickLocale(List<String> available, VoiceLanguage language) {
    String norm(String id) => id.replaceAll('-', '_').toLowerCase();
    final preferred = language == VoiceLanguage.fr ? 'fr_fr' : 'ar_tn';
    final prefix = language == VoiceLanguage.fr ? 'fr' : 'ar';
    for (final id in available) {
      if (norm(id) == preferred) return id;
    }
    for (final id in available) {
      if (norm(id).startsWith('${prefix}_') || norm(id) == prefix) return id;
    }
    return null;
  }
}
