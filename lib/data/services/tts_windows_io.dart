import 'dart:io';

/// Fallback SAPI Windows (System.Speech) quand flutter_tts est silencieux.
Future<bool> speakWithWindowsSapi(String text) async {
  Directory? tmpDir;
  try {
    tmpDir = await Directory.systemTemp.createTemp('rentcar_tts_');
    final scriptFile = File('${tmpDir.path}\\speak.ps1');
    final safe = text
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll("'", "''");

    final script = '''
Add-Type -AssemblyName System.Speech
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$synth.Volume = 100
\$synth.Rate = -1
try {
  \$fr = \$synth.GetInstalledVoices() |
    Where-Object { \$_.VoiceInfo.Culture.Name -like 'fr*' } |
    Select-Object -First 1
  if (\$null -ne \$fr) { \$synth.SelectVoice(\$fr.VoiceInfo.Name) }
} catch {}
\$synth.Speak('$safe')
''';
    await scriptFile.writeAsString(script);

    final result = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ],
      runInShell: false,
    );
    return result.exitCode == 0;
  } catch (_) {
    return false;
  } finally {
    try {
      await tmpDir?.delete(recursive: true);
    } catch (_) {}
  }
}

Future<void> stopWindowsSapi() async {}
