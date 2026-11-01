import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get isWebSpeechSupported {
  try {
    // Accès = support ; getVoices() peut être vide au 1er appel.
    _synth.getVoices();
    return true;
  } catch (_) {
    return false;
  }
}

web.SpeechSynthesis get _synth => web.window.speechSynthesis;

web.SpeechSynthesisVoice? _preferredVoice;

void _refreshVoice() {
  final list = _synth.getVoices().toDart;
  web.SpeechSynthesisVoice? fr;
  web.SpeechSynthesisVoice? any;
  for (final v in list) {
    any ??= v;
    if (v.lang.toLowerCase().startsWith('fr')) {
      fr = v;
      break;
    }
  }
  _preferredVoice = fr ?? any;
}

/// Précharge les voix Chrome (souvent vides au 1er getVoices).
Future<void> warmUpWebSpeech() async {
  try {
    _refreshVoice();
    if (_preferredVoice != null) return;

    final completer = Completer<void>();
    late final JSFunction handler;
    handler = ((web.Event _) {
      _refreshVoice();
      if (_preferredVoice != null && !completer.isCompleted) {
        completer.complete();
      }
    }).toJS;

    _synth.addEventListener('voiceschanged', handler);
    _refreshVoice(); // force parfois le chargement
    await Future.any([
      completer.future,
      Future<void>.delayed(const Duration(milliseconds: 1500)),
    ]);
    _synth.removeEventListener('voiceschanged', handler);
    _refreshVoice();
  } catch (_) {}
}

Future<bool> speakWeb(
  String text, {
  void Function()? onStart,
  void Function()? onDone,
  void Function(String error)? onError,
}) async {
  try {
    if (!isWebSpeechSupported) {
      onError?.call('Lecture vocale non supportée dans ce navigateur.');
      return false;
    }

    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      onError?.call('Texte vide.');
      return false;
    }

    _refreshVoice();
    _synth.cancel();

    final utterance = web.SpeechSynthesisUtterance(cleaned);
    utterance.lang = _preferredVoice?.lang ?? 'fr-FR';
    utterance.rate = 1.0;
    utterance.pitch = 1.0;
    utterance.volume = 1.0;
    final voice = _preferredVoice;
    if (voice != null) {
      utterance.voice = voice;
    }

    utterance.onstart = ((web.SpeechSynthesisEvent _) {
      onStart?.call();
    }).toJS;

    utterance.onend = ((web.SpeechSynthesisEvent _) {
      onDone?.call();
    }).toJS;

    utterance.onerror = ((web.SpeechSynthesisErrorEvent event) {
      // "interrupted" / "canceled" = stop volontaire → pas une vraie erreur
      final err = event.error;
      if (err != 'interrupted' && err != 'canceled') {
        onError?.call(err);
      }
      onDone?.call();
    }).toJS;

    // Immédiat après le clic (politique autoplay Chrome).
    _synth.speak(utterance);
    onStart?.call();
    return true;
  } catch (e) {
    onError?.call(e.toString());
    return false;
  }
}

void stopWebSpeech() {
  try {
    _synth.cancel();
  } catch (_) {}
}
