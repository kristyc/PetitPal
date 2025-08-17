import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../providers.dart';
import '../services/llm_service.dart';
import '../utils/markdown.dart';
import '../widgets/typing_dots.dart';
import '../widgets/thinking_backdrop.dart';
import '../state/chat_phase.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  String? _currentRecPath;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (s == PlayerState.completed || s == PlayerState.stopped) {
        if (ref.read(chatPhaseProvider) == ChatPhase.speaking) {
          ref.read(chatPhaseProvider.notifier).state = ChatPhase.idle;
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<String> _newRecordPath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/pp_rec_$ts.m4a';
  }

  Future<void> _toggleRecord() async {
    final phase = ref.read(chatPhaseProvider);
    final listening = ref.read(listeningProvider);

    if (!listening && (phase == ChatPhase.idle)) {
      // Start listening
      try { await HapticFeedback.mediumImpact(); } catch (_) {}
      final has = await _recorder.hasPermission();
      if (!has) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mic permission required.')));
        return;
      }
      _currentRecPath = await _newRecordPath();
      await _recorder.start(const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ), path: _currentRecPath!);

      // Live STT
      try {
        _sttAvailable = await _stt.initialize();
        if (_sttAvailable) {
          await _stt.listen(
            onResult: (res) {
              ref.read(transcriptProvider.notifier).state = res.recognizedWords;
            },
            listenMode: stt.ListenMode.dictation,
          );
        }
      } catch (_) {}
      ref.read(listeningProvider.notifier).state = true;
      ref.read(chatPhaseProvider.notifier).state = ChatPhase.listening;
      ref.read(replyProvider.notifier).state = '';
      return;
    }

    // Stop listening and send
    try { await HapticFeedback.mediumImpact(); } catch (_) {}
    ref.read(listeningProvider.notifier).state = false;
    ref.read(chatPhaseProvider.notifier).state = ChatPhase.thinking;
    try { await _stt.stop(); } catch (_) {}
    final path = await _recorder.stop();
    final recPath = path ?? _currentRecPath;
    _currentRecPath = null;
    if (recPath == null) {
      ref.read(chatPhaseProvider.notifier).state = ChatPhase.idle;
      return;
    }

    // Load audio and send to worker
    final key = ref.read(openAiKeyProvider);
    if (key == null || key.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your API key in Settings')));
      ref.read(chatPhaseProvider.notifier).state = ChatPhase.idle;
      return;
    }

    try {
      final bytes = await File(recPath).readAsBytes();
      // FIX: pass current transcript directly instead of undefined getter
      final liveTextNow = ref.read(transcriptProvider);

      final res = await LlmService.voiceChat(
        audio: bytes,
        mimeType: 'audio/aac',
        openAiApiKey: key,
        voice: ref.read(voiceProvider) ?? 'alloy', 
      );

      final live = ref.read(transcriptProvider);
      ref.read(transcriptProvider.notifier).state = res.transcript ?? live;
      final cleaned = MarkdownUtils.clean(res.reply ?? '');
      ref.read(replyProvider.notifier).state = cleaned;

      if (res.audioBytes != null && res.audioBytes!.isNotEmpty) {
        final p = await _writeTemp(res.audioBytes!, 'reply.mp3');
        await _player.stop();
        await _player.play(DeviceFileSource(p));
        ref.read(chatPhaseProvider.notifier).state = ChatPhase.speaking;
      } else {
        ref.read(chatPhaseProvider.notifier).state = ChatPhase.idle;
      }
    } catch (e) {
      ref.read(replyProvider.notifier).state = 'Error: $e';
      ref.read(chatPhaseProvider.notifier).state = ChatPhase.idle;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('LLM error: $e')));
    }
  }

  Future<String> _writeTemp(List<int> data, String name) async {
    final dir = await getTemporaryDirectory();
    final p = '${dir.path}/$name';
    final f = File(p);
    await f.writeAsBytes(data, flush: true);
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = ref.watch(chatPhaseProvider);
    final reply = ref.watch(replyProvider);

    final thinking = phase == ChatPhase.thinking || phase == ChatPhase.speaking;
    final hasAnswer = reply.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetitPal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          )
        ],
      ),
      body: Stack(
        children: [
          ThinkingBackdrop(active: thinking),
          if (hasAnswer)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Text(
                        reply,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 22, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Center(child: _statusMessage(phase)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: GestureDetector(
                onTap: _toggleRecord,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 156, width: 156,
                  decoration: BoxDecoration(
                    color: (phase == ChatPhase.listening) ? theme.colorScheme.secondary : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                  ),
                  child: Icon(
                    (phase == ChatPhase.listening) ? Icons.stop : (thinking ? Icons.close : Icons.mic),
                    size: 56, color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusMessage(ChatPhase phase) {
    if (phase == ChatPhase.listening) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Listening', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          TypingDots(size: 14),
        ],
      );
    }
    if (phase == ChatPhase.thinking || phase == ChatPhase.speaking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Thinking', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          TypingDots(size: 14),
        ],
      );
    }
    return const Text('Ask anything!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600));
  }
}
