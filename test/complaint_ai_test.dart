import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/models/complaint.dart';
import 'package:rentcar_tunisia/data/services/complaint_ai.dart';

void main() {
  test('JSON strict', () {
    final a = parseComplaintAnalysis(
      '{"category":"panne","priority":"moyenne","tone":"calme",'
      '"summary":"La batterie est à plat."}',
    )!;
    expect(a.category, ComplaintCategory.panne);
    expect(a.priority, ComplaintPriority.moyenne);
    expect(a.tone, ComplaintTone.calme);
    expect(a.summary, 'La batterie est à plat.');
    expect(a.suggestedPriority, ComplaintPriority.moyenne);
  });

  test('fences markdown, texte autour, accents et variantes', () {
    final a = parseComplaintAnalysis('''
Voici l'analyse :
```json
{"category": "Propreté", "priority": "Basse", "tone": "très mécontent", "summary": "Voiture sale."}
```
''')!;
    expect(a.category, ComplaintCategory.proprete);
    expect(a.tone, ComplaintTone.tresMecontent);
  });

  test('très mécontent → priorité +1 niveau', () {
    ComplaintAiAnalysis a(String p) => parseComplaintAnalysis(
      '{"category":"autre","priority":"$p","tone":"tresMecontent","summary":""}',
    )!;
    expect(a('basse').suggestedPriority, ComplaintPriority.moyenne);
    expect(a('moyenne').suggestedPriority, ComplaintPriority.urgente);
    expect(a('urgente').suggestedPriority, ComplaintPriority.urgente);
    expect(a('basse').priorityRaised, isTrue);
    expect(a('urgente').priorityRaised, isFalse);
  });

  test('réponses inutilisables → null', () {
    expect(parseComplaintAnalysis(''), isNull);
    expect(parseComplaintAnalysis('pas de json'), isNull);
    expect(
      parseComplaintAnalysis('{"category":"inconnue","priority":"x"}'),
      isNull,
    );
  });

  test('le prompt contient le texte du client échappé', () {
    final p = buildComplaintAnalysisPrompt(
      title: 'Clim "HS"',
      description: 'Ligne 1\nLigne 2',
    );
    expect(p, contains(r'"Clim \"HS\""'));
    expect(p, contains(r'Ligne 1\nLigne 2'));
  });

  test('aiSummary / aiTone : aller-retour JSON', () {
    final now = DateTime(2026, 10, 30);
    final c = Complaint(
      id: 'a',
      reference: 'REC-2026-0001',
      userId: 'u',
      category: ComplaintCategory.panne,
      title: 't',
      description: 'd',
      priority: ComplaintPriority.urgente,
      status: ComplaintStatus.enAttente,
      createdAt: now,
      updatedAt: now,
      aiSummary: 'Résumé',
      aiTone: ComplaintTone.mecontent,
    );
    final back = Complaint.fromJson(c.toJson());
    expect(back.aiSummary, 'Résumé');
    expect(back.aiTone, ComplaintTone.mecontent);
  });
}
