import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// Coordonnées de l'agence pour l'assistance panne.
/// Numéro fictif (le même que « Assistance » dans le profil) : à remplacer
/// par le vrai numéro de l'agence.
abstract final class ComplaintContacts {
  static const agencyPhone = '+21671000000';
  static const agencyPhoneDisplay = '+216 71 000 000';
}

/// Ouvre le composeur avec le numéro de l'agence (tel:).
Future<void> callAgency(BuildContext context) async {
  final l = context.l10n;
  final uri = Uri(scheme: 'tel', path: ComplaintContacts.agencyPhone);
  var ok = false;
  try {
    ok = await launchUrl(uri);
  } catch (e) {
    debugPrint('[Complaints] Appel impossible : $e');
  }
  if (!ok && context.mounted) {
    AppSnack.error(
      context,
      l.urgentCallFailed(ComplaintContacts.agencyPhoneDisplay),
    );
  }
}

/// Ouvre la position dans l'app Maps (ou le navigateur à défaut).
Future<void> openInMaps(BuildContext context, double lat, double lng) async {
  final l = context.l10n;
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$lat,$lng',
  });
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[Complaints] Maps impossible : $e');
  }
  if (!ok && context.mounted) AppSnack.error(context, l.complaintMapsFailed);
}
