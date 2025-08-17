import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import '../providers.dart';
import '../services/llm_service.dart';
import '../widgets/typing_dots.dart';
import '../widgets/thinking_backdrop.dart';
import '../dev_settings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  final AudioPlayer _player = AudioPlayer();
  int _session = 0;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.stop);
    _player.onPlayerStateChanged.listen((s) { setState(() { _isSpeaking = s == PlayerState.playing; }); });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _sttAvailable = await _stt.initialize(
        onStatus: (s) => debugPrint('stt status: ' + s),
        onError: (e) => debugPrint('stt error: ' + e.errorMsg),
      );
    } catch (e) {
      debugPrint('stt init failed: $e');
    }
  }

  @override
  void dispose() {
    try { _stt.stop(); } catch (_) {}
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    final recording = ref.read(listeningProvider);
    if (!recording) {
      // START
      try { await _player.stop(); } catch (_) {}
      _session++;

      if (!DevSettings.disableHaptics) { await HapticFeedback.mediumImpact(); }

      await Permission.microphone.request();
      final has = await _recorder.hasPermission();
      if (!has) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mic permission denied')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/petitpal_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      if (!_sttAvailable) {
        try { _sttAvailable = await _stt.initialize(); } catch (_) {}
      }
      if (_sttAvailable) {
        try {
          final sys = await _stt.systemLocale();
          final loc = sys?.localeId;
          await _stt.listen(
            onResult: (res) {
              ref.read(transcriptProvider.notifier).state = res.recognizedWords;
            },
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
            localeId: loc,
            pauseFor: const Duration(seconds: 60),
            listenFor: const Duration(minutes: 10),
          );
        } catch (e) {
          debugPrint('stt.listen failed: $e');
        }
      }

      ref.read(listeningProvider.notifier).state = true;
      ref.read(transcriptProvider.notifier).state = '';
      ref.read(replyProvider.notifier).state = '';
    } else {
      // STOP
      if (!DevSettings.disableHaptics) { await HapticFeedback.mediumImpact(); }
      ref.read(listeningProvider.notifier).state = false;
      final int reqSession = _session;
      ref.read(answeringProvider.notifier).state = true;

      // Only stop STT now -> OS end chime plays once on purpose.
      try { await _stt.stop(); } catch (_) {}

      final path = await _recorder.stop();
      if (path == null) {
        ref.read(answeringProvider.notifier).state = false;
        return;
      }

      final file = File(path);
      final bytes = await file.readAsBytes();

      final key = ref.read(openAiKeyProvider);
      if (key == null || key.isEmpty) {
        ref.read(answeringProvider.notifier).state = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please set your OpenAI key in Settings.')),
          );
        }
        return;
      }
      try {
        final ttsVoice = ref.read(voiceProvider);
        final res = await LlmService.voiceChat(
          audio: bytes,
          mimeType: 'audio/m4a',
          openAiApiKey: key,
          voice: ttsVoice,
        );
        if (reqSession == _session) {
          final live = ref.read(transcriptProvider);
          ref.read(transcriptProvider.notifier).state = res.transcript ?? live;
          ref.read(replyProvider.notifier).state = res.reply ?? '';
        }
        ref.read(answeringProvider.notifier).state = false;

        if (reqSession == _session && !ref.read(listeningProvider) && res.audioBytes != null && res.audioBytes!.isNotEmpty) {
          final dir = await getTemporaryDirectory();
          final p = '${dir.path}/reply_${DateTime.now().millisecondsSinceEpoch}.mp3';
          final f = File(p);
          await f.writeAsBytes(res.audioBytes!);
          await _player.stop();
          await _player.setVolume(1.0);
          await _player.play(DeviceFileSource(p));
        }
      } catch (e) {
        ref.read(answeringProvider.notifier).state = false;
        ref.read(replyProvider.notifier).state = 'Error: $e';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('LLM error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recording = ref.watch(listeningProvider);
    final transcript = ref.watch(transcriptProvider);
    final reply = ref.watch(replyProvider);
    final answering = ref.watch(answeringProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetitPal'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThinkingBackdrop(active: answering || _isSpeaking)),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('👋', style: TextStyle(fontSize: 48)),
                        const SizedBox(width: 16),
                        Expanded(child: Text('Ask me anything!', style: theme.textTheme.bodyLarge)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                    // Your Question (Transcript)
                    Text('Your Question', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        transcript.isEmpty ? (recording ? 'Listening…' : '—') : transcript,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Answer
                    Text('Answer', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: answering
                          ? Row(children: const [TypingDots(), SizedBox(width: 8), Text('Thinking…')])
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 360),
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  child: Text(reply.isEmpty ? '—' : reply),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: GestureDetector(
                    onTap: () async { if (_isSpeaking) { await _player.stop(); return; } await _toggleRecord(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: recording ? 156 : 148,
                      width: recording ? 156 : 148,
                      decoration: BoxDecoration(
                        color: recording ? theme.colorScheme.secondary : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
                      ),
                      child: Icon(
                        recording ? Icons.stop : (_isSpeaking ? Icons.close : Icons.mic),
                        size: 68,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
