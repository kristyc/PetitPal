import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/llm_service.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _voices = const ['alloy','echo','fable','onyx','nova','shimmer','coral','verse','ballad','ash','sage'];
  final AudioPlayer _player = AudioPlayer();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _openAiController;

  @override
  void initState() {
    super.initState();
    _openAiController = TextEditingController();
    Future.microtask(() {
      final k = ref.read(openAiKeyProvider);
      if (k != null) _openAiController.text = k;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _openAiController.dispose();
    super.dispose();
  }

  Future<void> _requestMic() async {
    await Permission.microphone.request();
    if (mounted) setState(() {});
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LLM Provider Keys', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _openAiController,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API Key',
                      hintText: 'sk-...',
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your OpenAI API key';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            ref.read(openAiKeyProvider.notifier).state = _openAiController.text;
                            FocusScope.of(context).unfocus();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved')),
                              );
                            }
                          }
                        },
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => _openAiController.text = '',
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('OpenAI TTS Voice', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Consumer(builder: (context, ref2, _) {
                    final current = ref2.watch(voiceProvider);
                    return Column(
                      children: _voices.map((v) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(v),
                        leading: Radio<String>(
                          value: v,
                          groupValue: current,
                          onChanged: (val) {
                            if (val != null) {
                              ref2.read(voiceProvider.notifier).save(val);
                            }
                          },
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Preview',
                          onPressed: () async {
                            final key = ref.read(openAiKeyProvider);
                            if (key == null || key.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set OpenAI key first.')));
                              return;
                            }
                            try {
                              final bytes = await LlmService.ttsSample(openAiApiKey: key, voice: v, text: 'Hello from the ' + v + ' voice.');
                              final dir = await getTemporaryDirectory();
                              final p = dir.path + '/sample_' + v + '.mp3';
                              final f = File(p);
                              await f.writeAsBytes(bytes);
                              await _player.stop();
                              await _player.play(DeviceFileSource(p));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
                            }
                          },
                        ),
                      )).toList(),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text('Microphone permission', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  FutureBuilder<PermissionStatus>(
                    future: Permission.microphone.status,
                    builder: (context, snap) {
                      final st = snap.data;
                      final granted = st == PermissionStatus.granted;
                      return Row(
                        children: [
                          Icon(granted ? Icons.check_circle : Icons.error, color: granted ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Text(granted ? 'Granted' : (st?.toString() ?? 'Unknown')),
                          const Spacer(),
                          TextButton(onPressed: _requestMic, child: const Text('Request')),
                          TextButton(onPressed: _openAppSettings, child: const Text('Open Settings')),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/diagnostics'),
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Open Diagnostics'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: If emulator records silence, open emulator “⋮ → Microphone” and enable host audio input. '
                    'On Windows, allow “desktop apps” mic access.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
