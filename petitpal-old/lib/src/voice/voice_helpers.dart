import 'package:flutter_tts/flutter_tts.dart';
class VoiceHelpers {
  static final _tts = FlutterTts();
  static Future<void> speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }
}
