/// Scan du permis de conduire par OCR (ML Kit, hors ligne, script latin).
///
/// - Android / iOS → ML Kit (`licence_scan_ocr_io.dart`)
/// - Web → non pris en charge (`licence_scan_ocr_stub.dart`) : ML Kit
///   importe dart:io, qui casserait la compilation web.
///
/// L'extraction du numéro et de la date est dans `licence_text_parser.dart`
/// (fonction pure, testée).
library;

export 'licence_scan_ocr_stub.dart'
    if (dart.library.io) 'licence_scan_ocr_io.dart';
export 'licence_text_parser.dart';
