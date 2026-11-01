import 'licence_text_parser.dart';

/// Web : ML Kit n'existe pas dans le navigateur.
class LicenceScanService {
  const LicenceScanService();

  bool get isSupported => false;

  Future<LicenceScanResult> scan(String imagePath) async =>
      throw const LicenceScanException('OCR indisponible sur le web');
}
