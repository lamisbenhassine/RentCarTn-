import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// « à l'instant », « il y a 5 min », « il y a 3 heures », « hier »,
/// « il y a 4 jours », puis la date (au-delà de 30 jours).
/// Fonction pure (testée) : [now] est injectable.
String relativeTime(AppLocalizations l, DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(date);

  if (diff.inMinutes < 1) return l.timeJustNow;
  if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);

  // Jours calendaires (hier = la veille, même s'il y a moins de 24 h × 2).
  final days = DateTime(
    current.year,
    current.month,
    current.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days <= 30) return l.timeDaysAgo(days < 1 ? 1 : days);
  return DateFormat.yMMMd(l.localeName).format(date);
}
