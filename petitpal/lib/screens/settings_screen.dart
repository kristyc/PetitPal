import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import '../config/app_config.dart';
import '../services/llm_service.dart';
import '../widgets/save_background_api_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _voices = const ['alloy','echo','fable','onyx','nova','shimmer','coral','verse','ballad','ash','sage'];
  final _player = AudioPlayer();
  final _apiKeyCtrl = TextEditingController();
  bool _verifying = false;
  bool _valid = false;
  bool _voiceLoading = false;

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(openAiKeyProvider);
    if (currentKey != null) _apiKeyCtrl.text = currentKey;
    _restoreVerifiedFlag();
  }

  Future<void> _restoreVerifiedFlag() async {
	  final prefs = await SharedPreferences.getInstance();
	  final saved = prefs.getBool('openai_key_verified') ?? false;
	  final keyAtSave = prefs.getString('openai_key_value') ?? '';
	  final current = ref.read(openAiKeyProvider) ?? '';
	  setState(() {
		_valid = saved && keyAtSave.isNotEmpty && keyAtSave == current;
	  });
	}

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  String _titleCase(String v) {
    if (v.isEmpty) return v;
    return v.substring(0,1).toUpperCase() + v.substring(1).toLowerCase();
  }

  Future<void> _previewVoice(String voice) async {
    final key = ref.read(openAiKeyProvider);
    if (key == null || key.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your API key first.')));
      return;
    }
    setState(() { _voiceLoading = true; });
    try {
      final bytes = await LlmService.ttsSample(openAiApiKey: key, voice: voice, text: 'Hello from the $voice voice.');
      final dir = await getTemporaryDirectory();
      final p = '${dir.path}/sample_$voice.mp3';
      final f = File(p);
      await f.writeAsBytes(bytes);
      await _player.stop();
      await _player.play(DeviceFileSource(p));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
    } finally {
      if (mounted) setState(() { _voiceLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voice = ref.watch(voiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- API KEY SECTION ---
          Row(
            children: [
              Text('OpenAI API Key', style: theme.textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () => launchUrl(Uri.parse('https://platform.openai.com/api-keys'), mode: LaunchMode.externalApplication),
                child: const Text('Get Key'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_valid) const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
              Expanded(
                child: TextField(
                  controller: _apiKeyCtrl,
                  onChanged: (_) { if (_valid) setState(() { _valid = false; }); },
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  final v = _apiKeyCtrl.text.trim();
                  ref.read(openAiKeyProvider.notifier).state = v;
                  if (v.isEmpty) { setState(() { _valid = false; }); return; }
                  setState(() { _verifying = true; });
                  final ok = await LlmService.verifyApiKey(openAiApiKey: v);
                  if (!mounted) return;
                  setState(() { _verifying = false; _valid = ok; });
                  final prefs = await SharedPreferences.getInstance();
                  if (ok) {
                    await prefs.setBool('openai_key_verified', true);
                    await prefs.setString('openai_key_value', v);					
					// Save for homescreen widget Foreground Service (no hardcoded URLs)
					await saveBackgroundApiConfig(
					  openAiKey: v,
					  workerBase: AppConfig.normalizedWorkerBaseUrl,
					);
                  } else {
                    await prefs.setBool('openai_key_verified', false);
                    await prefs.remove('openai_key_value');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key invalid.')));
                  }
                },
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              if (_verifying) const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth: 2)),
              // Removed the duplicate green tick here – it now only shows next to the field.
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // --- MIC SECTION ---
          Text('Microphone', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          FutureBuilder<PermissionStatus>(
            future: Permission.microphone.status,
            builder: (context, snap) {
              final granted = snap.data == PermissionStatus.granted;
              if (granted) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Thank you for granting mic permissions'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => openAppSettings(),
                        child: const Text('Manage in system settings'),
                      ),
                    ),
                  ],
                );
              } else {
                return ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Request Permission'),
                  onPressed: () async {
                    await Permission.microphone.request();
                    setState(() {});
                  },
                );
              }
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // --- VOICE SECTION ---
          Text('AI Voices', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Choose your preferred tone of voice'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: voice,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: _voiceLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
            ),
            selectedItemBuilder: (ctx) => _voices.map((v) {
              final sel = v == voice;
              return Row(
                children: [
                  if (sel) const Icon(Icons.check_circle, color: Colors.green),
                  if (sel) const SizedBox(width: 6),
                  Text(_titleCase(v)),
                ],
              );
            }).toList(),
            items: _voices.map((v) => DropdownMenuItem(
              value: v,
              child: Row(
                children: [
                  if (v == voice) const Icon(Icons.check_circle, color: Colors.green),
                  if (v == voice) const SizedBox(width: 6),
                  Text(_titleCase(v)),
                ],
              ),
            )).toList(),
            onChanged: (val) async {
              if (val == null) return;
              ref.read(voiceProvider.notifier).save(val);
              await _previewVoice(val);
            },
          ),
        ],
      ),
    );
  }
}
