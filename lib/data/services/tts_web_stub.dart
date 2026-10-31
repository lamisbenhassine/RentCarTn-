/// Stub non-web.
bool get isWebSpeechSupported => false;

Future<void> warmUpWebSpeech() async {}

Future<bool> speakWeb(
  String text, {
  void Function()? onStart,
  void Function()? onDone,
  void Function(String error)? onError,
}) async =>
    false;

void stopWebSpeech() {}
