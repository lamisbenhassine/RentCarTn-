import 'package:rentcar_tunisia/data/services/gemini_service.dart';

Future<void> main() async {
  final service = GeminiService();
  final result = await service.testConnection();
  print(result.ok ? 'OK: ${result.message}' : 'FAIL: ${result.message}');
  service.dispose();
}
