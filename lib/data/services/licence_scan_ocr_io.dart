import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'licence_text_parser.dart';

/// OCR ML Kit (modèle latin embarqué : fonctionne sans internet).
class LicenceScanService {
  const LicenceScanService();

  bool get isSupported => true;

  /// Lit l'image [imagePath] et en extrait numéro + date d'expiration.
  Future<LicenceScanResult> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      debugPrint('[LicenceScan] Texte reconnu :\n${recognized.text}');
      return parseLicenceText(recognized.text);
    } catch (e) {
      debugPrint('[LicenceScan] Échec OCR : $e');
      throw LicenceScanException('$e');
    } finally {
      await recognizer.close();
    }
  }
}
