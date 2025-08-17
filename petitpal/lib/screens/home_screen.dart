import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers.dart';
import '../services/llm_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.9);
    await _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    final recording = ref.read(listeningProvider);
    if (!recording) {
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
          sampleRate: 44100),
        path: filePath,
      );
      ref.read(listeningProvider.notifier).state = true;
      ref.read(transcriptProvider.notifier).state = '';
      ref.read(replyProvider.notifier).state = '';
    } else {
      ref.read(listeningProvider.notifier).state = false;
      final path = await _recorder.stop();
      if (path == null) return;
      final file = File(path);
      final bytes = await file.readAsBytes();

      final key = ref.read(openAiKeyProvider);
      if (key == null || key.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please set your OpenAI key in Settings.')),
          );
        }
        return;
      }
      try {
        final res = await LlmService.voiceChat(audio: bytes, mimeType: 'audio/m4a', openAiApiKey: key);
        ref.read(transcriptProvider.notifier).state = res.transcript ?? '';
        ref.read(replyProvider.notifier).state = res.reply ?? '';
        if ((res.reply ?? '').isNotEmpty) {
          await _tts.speak(res.reply!);
        }
      } catch (e) {
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/app/intro.png', height: 56, width: 56, errorBuilder: (_, __, ___) => const Icon(Icons.local_florist, size: 56)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text('Ask me anything by voice!',
                                  style: theme.textTheme.bodyLarge),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap the mic, speak your question, tap again to send. I’ll transcribe and answer, then speak back.',
                          style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (transcript.isNotEmpty) ...[
                  Text('Transcript', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(transcript),
                  ),
                  const SizedBox(height: 16),
                ],
                if (reply.isNotEmpty) ...[
                  Text('Answer', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(reply),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecord,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: recording ? 96 : 88,
                  width: recording ? 96 : 88,
                  decoration: BoxDecoration(
                    color: recording ? theme.colorScheme.secondary : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
                  ),
                  child: Icon(
                    recording ? Icons.stop : Icons.mic,
                    size: 44,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
