import '../../data/models/complaint.dart';
import '../../l10n/l10n.dart';

/// Libellés traduits (fr / en / ar) des énumérations du module
/// Réclamations. Les extensions du modèle (`.label`) restent en français
/// pour les données (historique) ; l'interface utilise celles-ci.
extension ComplaintL10n on AppLocalizations {
  String complaintCategory(ComplaintCategory c) => switch (c) {
    ComplaintCategory.panne => complaintCatPanne,
    ComplaintCategory.proprete => complaintCatProprete,
    ComplaintCategory.retardAgence => complaintCatRetardAgence,
    ComplaintCategory.facturation => complaintCatFacturation,
    ComplaintCategory.enchere => complaintCatEnchere,
    ComplaintCategory.autre => complaintCatAutre,
  };

  String complaintStatus(ComplaintStatus s) => switch (s) {
    ComplaintStatus.enAttente => complaintStatusEnAttente,
    ComplaintStatus.enCours => complaintStatusEnCours,
    ComplaintStatus.resolue => complaintStatusResolue,
    ComplaintStatus.rejetee => complaintStatusRejetee,
  };

  String complaintPriority(ComplaintPriority p) => switch (p) {
    ComplaintPriority.basse => complaintPriorityBasse,
    ComplaintPriority.moyenne => complaintPriorityMoyenne,
    ComplaintPriority.urgente => complaintPriorityUrgente,
  };

  String complaintTone(ComplaintTone t) => switch (t) {
    ComplaintTone.calme => aiToneCalme,
    ComplaintTone.mecontent => aiToneMecontent,
    ComplaintTone.tresMecontent => aiToneTresMecontent,
  };
}
