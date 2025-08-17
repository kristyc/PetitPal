import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../config.dart';
import '../providers.dart';
import '../services/llm_service.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});
  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  final _log = <String>[];
  bool _running = false;

  final _recorder = AudioRecorder();
  String? _filePath;
  int _fileSize = 0;
  final _player = AudioPlayer();
  final _tts = FlutterTts();

  bool _useWav = false; // toggle between AAC(M4A) and WAV for testing

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(1.0);
    _player.onPlayerComplete.listen((_) {
      _add('■ Playback completed');
    });
  }

  String _mimeFromPath(String path) {
    if (path.toLowerCase().endsWith('.wav')) return 'audio/wav';
    return 'audio/m4a';
  }

  void _add(String s) {
    debugPrint('[Diag] ' + s);
    setState(() => _log.add(s));
  }

  Future<void> _runChecks() async {
    if (_running) return;
    setState(() => _running = true);
    _log.clear();

    try {
      _add('Worker base: ' + AppConfig.normalizedWorkerBaseUrl);

      // 1) Key present
      final key = ref.read(openAiKeyProvider);
      if (key == null || key.isEmpty) {
        _add('❌ OpenAI key: NOT SET (go to Settings)');
        return;
      } else {
        _add('✅ OpenAI key: present (length ${key.length})');
      }

      // 2) Text ping to /api/chat
      try {
        final r = await http.post(
          Uri.parse('${AppConfig.normalizedWorkerBaseUrl}/api/chat'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + key.trim(),
          },
          body: '{"text":"diagnostic ping","model":"'+AppConfig.defaultModel+'"}',
        );
        _add('HTTP POST /api/chat -> ' + r.statusCode.toString());
        _add('Body (first 300): ' + (r.body.length > 300 ? r.body.substring(0,300) : r.body));
        if (r.statusCode != 200) {
          _add('❌ /api/chat failed. Check worker logs and Authorization header.');
          return;
        } else {
          _add('✅ /api/chat reachable.');
        }
      } catch (e) {
        _add('❌ Worker /api/chat error: ' + e.toString());
        return;
      }

      // 3) Quick 2s record and send to /api/voice_chat
      final hasPerm = await _recorder.hasPermission();
      _add('Mic permission: ' + (hasPerm ? 'granted' : 'denied'));
      if (!hasPerm) {
        _add('❌ Grant microphone permission and retry.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final ext = _useWav ? 'wav' : 'm4a';
      final filePath = '${dir.path}/diag_${DateTime.now().millisecondsSinceEpoch}.' + ext;
      final cfg = _useWav
          ? const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, bitRate: 128000)
          : const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000);
      await _recorder.start(cfg, path: filePath);
      _add('Recording 2 seconds... (${_useWav ? 'WAV' : 'M4A'})');
      final sub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 150)).listen((amp) {
        _add('amp current: ' + amp.current.toString() + ', max: ' + amp.max.toString());
      });
      await Future.delayed(const Duration(seconds: 2));
      final path = await _recorder.stop();
      try { await sub.cancel(); } catch (_) {}
      if (path == null) {
        _add('❌ Recorder returned null path.');
        return;
      }
      final f = File(path);
      if (!await f.exists()) {
        _add('❌ Recorded file not found: $path');
        return;
      }
      _filePath = path;
      _fileSize = await f.length();
      setState(() {});
      _add('✅ Recorded file: $path (${_fileSize} bytes)');

      final bytes = await f.readAsBytes();

      _add('POST /api/voice_chat ...');
      try {
        final res = await LlmService.voiceChat(
          audio: bytes,
          mimeType: _mimeFromPath(_filePath!),
          openAiApiKey: key!,
        );
        _add('Transcript: ' + (res.transcript ?? '(none)'));
        _add('Reply: ' + (res.reply ?? '(none)'));
        if ((res.reply ?? '').isNotEmpty) {
          _add('✅ End-to-end pipeline OK.');
        } else {
          _add('⚠ End-to-end returned empty reply.');
        }
      } catch (e) {
        _add('❌ Voice chat error: $e');
      }
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _record3s() async {
    _log.clear();
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      _add('❌ Mic permission denied.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final ext = _useWav ? 'wav' : 'm4a';
    _filePath = '${dir.path}/diag_play_${DateTime.now().millisecondsSinceEpoch}.' + ext;
    final cfg = _useWav
        ? const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, bitRate: 128000)
        : const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000);
    await _recorder.start(cfg, path: _filePath!);
    _add('Recording 3 seconds... speak now (${_useWav ? 'WAV' : 'M4A'})');
    final sub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 150)).listen((amp) {
      _add('amp current: ' + amp.current.toString() + ', max: ' + amp.max.toString());
    });
    await Future.delayed(const Duration(seconds: 3));
    final path = await _recorder.stop();
    try { await sub.cancel(); } catch (_) {}
    if (path == null) {
      _add('❌ Recorder returned null path.');
      return;
    }
    final f = File(path);
    _fileSize = await f.length();
    setState(() {});
    _add('✅ Saved: $path (${_fileSize} bytes)');
  }

  Future<void> _play() async {
    if (_filePath == null) {
      _add('No recording to play.');
      return;
    }
    await _player.stop();
    await _player.setVolume(1.0);
    await _player.play(DeviceFileSource(_filePath!));
    _add('▶ Playing');
  }

  Future<void> _ttsBeep() async {
    await _tts.stop();
    await _tts.setSpeechRate(0.9);
    await _tts.setPitch(1.0);
    await _tts.speak('Test audio. This verifies your playback path is working.');
    _add('🔊 TTS test spoken');
  }

  Future<void> _sendRecording() async {
    if (_filePath == null) {
      _add('No recording to send.');
      return;
    }
    final key = ref.read(openAiKeyProvider);
    if (key == null || key.isEmpty) {
      _add('❌ Set OpenAI key first.');
      return;
    }
    final bytes = await File(_filePath!).readAsBytes();
    _add('POST /api/voice_chat with the just-recorded file... (${_mimeFromPath(_filePath!)})');
    try {
      final res = await LlmService.voiceChat(audio: bytes, mimeType: _mimeFromPath(_filePath!), openAiApiKey: key);
      _add('Transcript: ' + (res.transcript ?? '(none)'));
      _add('Reply: ' + (res.reply ?? '(none)'));
    } catch (e) {
      _add('❌ Voice chat error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _running ? null : _runChecks,
                  child: const Text('Run Checks'),
                ),
                OutlinedButton.icon(
                  onPressed: _record3s,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Record 3s Test'),
                ),
                // Encoder toggle
                FilterChip(
                  label: Text(_useWav ? 'WAV' : 'M4A'),
                  selected: _useWav,
                  onSelected: (v) => setState(() => _useWav = v),
                  avatar: const Icon(Icons.swap_horiz),
                ),
                OutlinedButton.icon(
                  onPressed: _play,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Recording'),
                ),
                OutlinedButton.icon(
                  onPressed: _sendRecording,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Send Recording to Worker'),
                ),
                OutlinedButton.icon(
                  onPressed: _ttsBeep,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('TTS Beep'),
                ),
              ],
            ),
          ),
          if (_filePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recording: ${_filePath} (${_fileSize} bytes)'),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(_log[i]),
            ),
          )
        ],
      ),
    );
  }
}
