/// Extraction du numéro de permis et de la date d'expiration à partir du
/// texte OCR (partie latine du permis tunisien, français / arabe).
///
/// Fonction pure : aucune dépendance Flutter / ML Kit → testable avec de
/// simples chaînes de caractères (voir test/licence_text_parser_test.dart).
library;

/// Résultat de l'analyse d'un permis.
class LicenceScanResult {
  const LicenceScanResult({
    this.licenceNumber,
    this.expiry,
    this.rawText = '',
  });

  final String? licenceNumber;
  final DateTime? expiry;

  /// Texte brut reconnu (utile pour le débogage).
  final String rawText;

  bool get isEmpty => licenceNumber == null && expiry == null;
  bool get isComplete => licenceNumber != null && expiry != null;

  /// Permis expiré à la date [now] (valable jusqu'au jour inclus).
  bool isExpired({DateTime? now}) {
    final e = expiry;
    if (e == null) return false;
    final today = now ?? DateTime.now();
    return DateTime(e.year, e.month, e.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }
}

/// Mots qui annoncent la date de fin de validité.
final _expiryKeywords = RegExp(
  r"(expir|valable|validit|fin\s+de|jusqu|date\s+limite|valid\s+until|"
  r'\b4\s*b\b)',
  caseSensitive: false,
);

/// Mots qui annoncent le numéro de permis.
final _numberKeywords = RegExp(
  r'(permis|licen[cs]e|n\s*[°ºo]\.?|num[ée]ro|\b5\s*[.)]?\s)',
  caseSensitive: false,
);

/// jj/mm/aaaa, jj-mm-aaaa, jj.mm.aaaa (espaces tolérés autour du séparateur).
final _date = RegExp(r'\b(\d{1,2})\s*[/.\-]\s*(\d{1,2})\s*[/.\-]\s*(\d{4})\b');

/// Formes de numéro reconnues (de la plus sûre à la moins sûre).
final _numberPatterns = <RegExp>[
  RegExp(r'\b\d{2}\s*/\s*\d{5,8}\b'), // 09/123456 (format tunisien)
  RegExp(r'\bTN[-\s]?\d{4}[-\s]?\d{4,8}\b', caseSensitive: false),
  RegExp(r'\b[A-Z]{1,3}[-\s]?\d{5,10}\b'),
  RegExp(r'\b\d{6,10}\b'),
];

/// Analyse le texte OCR. [now] sert à écarter les dates absurdes.
LicenceScanResult parseLicenceText(String text, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final lines = text
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  return LicenceScanResult(
    licenceNumber: _findNumber(lines),
    expiry: _findExpiry(lines, today),
    rawText: text,
  );
}

// -----------------------------------------------------------------------------
// Date d'expiration
// -----------------------------------------------------------------------------

DateTime? _findExpiry(List<String> lines, DateTime today) {
  // 1) Date sur la même ligne qu'un mot-clé, ou sur la ligne suivante.
  for (var i = 0; i < lines.length; i++) {
    if (!_expiryKeywords.hasMatch(lines[i])) continue;
    final sameLine = _datesIn(lines[i], today);
    if (sameLine.isNotEmpty) return _latest(sameLine);
    if (i + 1 < lines.length) {
      final next = _datesIn(lines[i + 1], today);
      if (next.isNotEmpty) return _latest(next);
    }
  }

  // 2) Sinon : la date la plus tardive du document (naissance < délivrance
  //    < expiration). Il faut au moins deux dates pour ne pas prendre la
  //    date de naissance seule pour une expiration.
  final all = [for (final l in lines) ..._datesIn(l, today)];
  if (all.length < 2) return null;
  return _latest(all);
}

List<DateTime> _datesIn(String line, DateTime today) {
  final dates = <DateTime>[];
  for (final m in _date.allMatches(line)) {
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final year = int.parse(m.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) continue;
    // Plage plausible pour un permis : naissance → expiration lointaine.
    if (year < today.year - 100 || year > today.year + 30) continue;
    final date = DateTime(year, month, day);
    if (date.day != day) continue; // ex. 31/02 → invalide
    dates.add(date);
  }
  return dates;
}

DateTime _latest(List<DateTime> dates) =>
    dates.reduce((a, b) => a.isAfter(b) ? a : b);

// -----------------------------------------------------------------------------
// Numéro de permis
// -----------------------------------------------------------------------------

String? _findNumber(List<String> lines) {
  // 1) Après un mot-clé (« Permis N° », « N° », « 5. »), même ligne ou
  //    ligne suivante.
  for (var i = 0; i < lines.length; i++) {
    final match = _numberKeywords.firstMatch(lines[i]);
    if (match == null) continue;
    final after = lines[i].substring(match.end);
    final found =
        _numberIn(after) ?? (i + 1 < lines.length ? _numberIn(lines[i + 1]) : null);
    if (found != null) return found;
  }
  // 2) Sinon : le premier motif « sûr » trouvé dans tout le texte
  //    (les nombres seuls ne sont pas assez fiables sans mot-clé).
  for (final pattern in _numberPatterns.take(3)) {
    for (final line in lines) {
      final m = pattern.firstMatch(_withoutDates(line));
      if (m != null) return _clean(m.group(0)!);
    }
  }
  return null;
}

String? _numberIn(String text) {
  final cleaned = _withoutDates(text);
  for (final pattern in _numberPatterns) {
    final m = pattern.firstMatch(cleaned);
    if (m != null) return _clean(m.group(0)!);
  }
  return null;
}

/// Retire les dates pour ne pas les prendre pour un numéro.
String _withoutDates(String line) => line.replaceAll(_date, ' ');

/// Normalise : espaces retirés autour du « / », majuscules.
String _clean(String raw) => raw
    .toUpperCase()
    .replaceAll(RegExp(r'\s*/\s*'), '/')
    .replaceAll(RegExp(r'\s+'), '-')
    .trim();

/// Échec du scan (OCR indisponible ou image illisible).
class LicenceScanException implements Exception {
  const LicenceScanException(this.message);
  final String message;

  @override
  String toString() => 'LicenceScanException: $message';
}
