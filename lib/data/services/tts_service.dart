import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_web_stub.dart' if (dart.library.html) 'tts_web_impl.dart' as web_tts;
import 'tts_windows_stub.dart'
    if (dart.library.io) 'tts_windows_io.dart' as win_tts;

/// Lecture vocale des panneaux.
/// - Chrome / web → SpeechSynthesis navigateur
/// - Android APK / iOS → flutter_tts natif
/// - Windows desktop → SAPI (fallback)
class TtsService extends ChangeNotifier {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  Future<void>? _initFuture;
  bool _ready = false;
  bool _speaking = false;
  String? _activeId;
  String? _lastError;
  String _language = 'fr-FR';
  Map<String, String>? _voice;

  bool get isSpeaking => _speaking;
  String? get activeId => _activeId;
  String? get lastError => _lastError;
  bool isSpeakingId(String id) => _speaking && _activeId == id;

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> ensureReady() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      if (kIsWeb) {
        await web_tts.warmUpWebSpeech();
        _ready = web_tts.isWebSpeechSupported;
        if (!_ready) {
          _lastError = 'Lecture vocale non supportée dans ce navigateur.';
        }
        return;
      }

      _tts.setStartHandler(() {
        _speaking = true;
        _lastError = null;
        notifyListeners();
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        _activeId = null;
        notifyListeners();
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        _activeId = null;
        notifyListeners();
      });
      _tts.setErrorHandler((msg) {
        _speaking = false;
        _activeId = null;
        _lastError = msg.toString();
        notifyListeners();
      });

      try {
        await _tts.setSharedInstance(true);
      } catch (_) {}

      await _selectVoiceAndLanguage();
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      try {
        await _tts.awaitSpeakCompletion(false);
      } catch (_) {}

      _ready = true;
      _lastError = null;
    } catch (e) {
      _ready = false;
      _lastError = e.toString();
      _initFuture = null;
    }
  }

  Future<void> _selectVoiceAndLanguage() async {
    try {
      final rawVoices = await _tts.getVoices;
      final voices = <Map<String, String>>[];
      if (rawVoices is List) {
        for (final v in rawVoices) {
          if (v is Map) {
            final name = v['name']?.toString();
            final locale = (v['locale'] ?? v['lang'])?.toString();
            if (name != null && locale != null) {
              voices.add({'name': name, 'locale': locale});
            }
          }
        }
      }

      Map<String, String>? fr;
      for (final v in voices) {
        if (v['locale']!.toLowerCase().startsWith('fr')) {
          fr = v;
          break;
        }
      }
      final chosen = fr ?? (voices.isNotEmpty ? voices.first : null);
      if (chosen != null) {
        _voice = chosen;
        _language = chosen['locale']!;
        try {
          await _tts.setVoice(chosen);
        } catch (_) {}
        await _tts.setLanguage(_language);
        return;
      }
    } catch (_) {}

    try {
      final raw = await _tts.getLanguages;
      if (raw is List) {
        for (final item in raw) {
          final have = item.toString();
          if (have.toLowerCase().startsWith('fr')) {
            _language = have;
            await _tts.setLanguage(_language);
            return;
          }
        }
        if (raw.isNotEmpty) {
          _language = raw.first.toString();
        }
      }
    } catch (_) {}
    await _tts.setLanguage(_language);
  }

  Future<void> speak({
    required String id,
    required String text,
  }) async {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      _lastError = 'Texte vide.';
      notifyListeners();
      return;
    }

    // Sur le web : ne PAS await l'init ici si déjà lancée — speak doit
    // rester collé au clic. On warm-up à l'ouverture de l'écran.
    if (!kIsWeb) {
      if (_initFuture == null) {
        await ensureReady();
      } else if (!_ready) {
        await _initFuture;
      }
    } else if (_initFuture == null) {
      // ignore: unawaited_futures
      ensureReady();
    }

    if (isSpeakingId(id)) {
      await stop();
      return;
    }

    _activeId = id;
    _speaking = true;
    _lastError = null;
    notifyListeners();

    // ——— Chrome / Flutter web ———
    if (kIsWeb) {
      final ok = await web_tts.speakWeb(
        cleaned,
        onStart: () {
          _speaking = true;
          _lastError = null;
          notifyListeners();
        },
        onDone: () {
          _speaking = false;
          _activeId = null;
          notifyListeners();
        },
        onError: (err) {
          _lastError = err;
          notifyListeners();
        },
      );
      if (!ok) {
        _speaking = false;
        _activeId = null;
        _lastError ??=
            'Chrome n\'a pas pu lire le texte. Autorisez le son du site '
            'et réessayez.';
        notifyListeners();
      }
      return;
    }

    // ——— Windows desktop ———
    if (_isWindowsDesktop) {
      final ok = await win_tts.speakWithWindowsSapi(cleaned);
      _speaking = false;
      _activeId = null;
      if (ok) {
        _lastError = null;
        notifyListeners();
        return;
      }
    }

    // ——— Android / iOS (APK release) ———
    final okPlugin = await _speakPlugin(cleaned);
    if (okPlugin) return;

    _speaking = false;
    _activeId = null;
    _lastError ??=
        'Impossible de lire le texte. Vérifiez le volume et les voix '
        'du téléphone.';
    notifyListeners();
  }

  Future<bool> _speakPlugin(String text) async {
    try {
      if (!_ready) await ensureReady();
      if (_voice != null) {
        try {
          await _tts.setVoice(_voice!);
        } catch (_) {}
      }
      await _tts.setLanguage(_language);
      await _tts.setVolume(1.0);

      try {
        await _tts.stop();
      } catch (_) {}

      final result = await _tts.speak(text);
      final ok = result == 1 ||
          result == '1' ||
          result == true ||
          result == null;
      return ok;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      web_tts.stopWebSpeech();
    } else {
      try {
        await _tts.stop();
      } catch (_) {}
      try {
        await win_tts.stopWindowsSapi();
      } catch (_) {}
    }
    _speaking = false;
    _activeId = null;
    notifyListeners();
  }
}
