enum PaymentMethod { carte, agence, virement }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.carte => 'Carte bancaire',
    PaymentMethod.agence => "Paiement à l'agence",
    PaymentMethod.virement => 'Virement bancaire',
  };

  String get description => switch (this) {
    PaymentMethod.carte =>
      'Visa, Mastercard ou e-Dinar — transaction simulée',
    PaymentMethod.agence =>
      'Réglez au comptoir lors de la prise du véhicule',
    PaymentMethod.virement =>
      'Instructions de virement envoyées par e-mail (démo)',
  };
}

enum PaymentStatus { enAttente, reussi, echoue, rembourse }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.enAttente => 'En attente',
    PaymentStatus.reussi => 'Payé',
    PaymentStatus.echoue => 'Échoué',
    PaymentStatus.rembourse => 'Remboursé',
  };
}

/// Trace de paiement simulée — aucune donnée bancaire réelle n'est conservée.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    this.maskedCard,
    this.failureReason,
  });

  final String id;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime date;

  /// Seuls les 4 derniers chiffres saisis sont gardés en mémoire locale.
  final String? maskedCard;
  final String? failureReason;
}
