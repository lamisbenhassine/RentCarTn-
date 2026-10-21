import 'package:rentcar_tunisia/data/mock/mock_learning.dart';
import 'package:rentcar_tunisia/data/services/gemini_service.dart';

Future<void> main() async {
  final service = GeminiService();
  print('Generating...');
  final result = await service.generateExam(
    signs: MockLearning.signs,
    rules: MockLearning.rules,
    questionCount: 3,
  );
  if (!result.ok) {
    print('FAIL: ${result.message}');
  } else {
    print('OK title=${result.title}');
    print('questions=${result.questions.length}');
    for (final q in result.questions) {
      print('- ${q.question} (correct=${q.correctIndex})');
    }
  }
  service.dispose();
}
