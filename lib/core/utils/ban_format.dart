import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/l10n.dart';

/// « 3 novembre 2026 14:30 » dans la langue de l'app.
String banDateTime(BuildContext context, DateTime d) =>
    DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_Hm()
        .format(d);

/// Temps restant : « 2 j 4 h », « 3 h 15 min », « 1 min 05 s ».
String banRemaining(AppLocalizations l, Duration d) {
  if (d.isNegative) d = Duration.zero;
  if (d.inDays > 0) return l.adminDurationDays(d.inDays, d.inHours % 24);
  if (d.inHours > 0) return l.adminDurationHours(d.inHours, d.inMinutes % 60);
  return l.durationMinSec(d.inMinutes, d.inSeconds % 60);
}
