import 'package:intl/intl.dart';

/// Formatage des valeurs affichées (dinar tunisien, dates FR, durées).
class Formatters {
  Formatters._();

  static final NumberFormat _tnd = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'TND',
    decimalDigits: 3,
  );

  static final NumberFormat _tndCompact = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'TND',
    decimalDigits: 0,
  );

  static final NumberFormat _number = NumberFormat.decimalPattern('fr_FR');

  /// Ex. « 180,000 TND »
  static String money(num value) => _tnd.format(value).trim();

  /// Ex. « 180 TND » — utilisé quand la précision n'apporte rien.
  static String moneyShort(num value) => _tndCompact.format(value).trim();

  static String number(num value) => _number.format(value);

  static String mileage(int km) => '${_number.format(km)} km';

  static String date(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);

  static String dateLong(DateTime d) =>
      DateFormat('d MMMM yyyy', 'fr_FR').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(d);

  static String time(DateTime d) => DateFormat('HH:mm', 'fr_FR').format(d);

  static String dayMonth(DateTime d) =>
      DateFormat('d MMM', 'fr_FR').format(d);

  /// Durée restante formatée pour les comptes à rebours d'enchères.
  static String countdown(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'Terminée';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) return '${days}j ${hours}h ${minutes}min';
    if (hours > 0) {
      return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
    }
    return '${_two(minutes)}:${_two(seconds)}';
  }

  static String relativePast(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return "À l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return date(d);
  }

  static String pluralDays(int n) => n <= 1 ? '$n jour' : '$n jours';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
