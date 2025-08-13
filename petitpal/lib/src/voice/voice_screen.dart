import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../config/strings_config.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _listening = false;
  String _preview = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetitPal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _listening ? Colors.amber : Colors.grey, width: 2),
              ),
              child: SingleChildScrollView(child: Text(_preview.isEmpty ? StringsConfig.listening : _preview)),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: Icon(_listening ? Icons.stop : Icons.mic),
              label: Text(_listening ? 'Stop' : StringsConfig.talkButton),
              onPressed: _listening ? _stopListening : _startListening,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startListening() async {
    final available = await _stt.initialize(onStatus: (s) {
      if (s == 'notListening') setState(() => _listening = false);
    }, onError: (e) {
      setState(() => _listening = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mic error: ${e.errorMsg}')));
    });
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech not available')));
      return;
    }
    setState(() { _listening = true; _preview=''; });
    await _stt.listen(onResult: (r) {
      setState(() => _preview = r.recognizedWords);
      if (_preview.trim().toLowerCase().endsWith('okay done')) {
        _stt.stop();
      }
    }, listenMode: stt.ListenMode.dictation, partialResults: true);
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _listening = false);
    await _tts.speak("You asked: ${_preview.isEmpty ? 'nothing yet' : _preview}. Would you like me to continue with more details?");
  }
}
