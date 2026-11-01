import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/models/complaint.dart';
import 'package:rentcar_tunisia/data/services/complaint_ai.dart';

void main() {
  test('reformulation : texte lu, tronqué à 1000, inutilisable → null', () {
    expect(
      parseComplaintRewrite(
        '{"text":"  Bonjour, la climatisation ne marche pas. "}',
      ),
      'Bonjour, la climatisation ne marche pas.',
    );
    final long = 'a' * 1200;
    expect(parseComplaintRewrite('{"text":"$long"}')!.length, 1000);
    expect(parseComplaintRewrite('{"text":""}'), isNull);
    expect(parseComplaintRewrite('pas de json'), isNull);
  });

  test(
    'solutions rapides : 3 maximum, vides ignorées, erreur → liste vide',
    () {
      expect(
        parseQuickFixes(
          '```json\n{"solutions":["Vérifier la boîte à gants"," ","B","C","D"]}\n```',
        ),
        ['Vérifier la boîte à gants', 'B', 'C', 'D'].take(3).toList(),
      );
      expect(parseQuickFixes('{"solutions":[]}'), isEmpty);
      expect(parseQuickFixes('{"autre":1}'), isEmpty);
      expect(parseQuickFixes('n/a'), isEmpty);
    },
  );

  test('les prompts contiennent la catégorie et le texte échappé', () {
    final p = buildQuickFixesPrompt(
      category: ComplaintCategory.panne,
      title: 'Voyant "moteur"',
      description: 'Allumé',
    );
    expect(p, contains('Catégorie : panne'));
    expect(p, contains(r'"Voyant \"moteur\""'));
    expect(
      buildComplaintRewritePrompt(title: 't', description: 'd'),
      contains("N'invente AUCUN fait"),
    );
  });
}
