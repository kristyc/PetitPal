import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/llm_keys.dart';

class ProviderSetupStep extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const ProviderSetupStep({super.key, required this.onDone});

  @override
  ConsumerState<ProviderSetupStep> createState() => _ProviderSetupStepState();
}

class _ProviderSetupStepState extends ConsumerState<ProviderSetupStep> {
  final _form = GlobalKey<FormState>();
  final _provider = ValueNotifier<String>('openai');
  final _keyCtrl = TextEditingController();
  bool _saving = false;
  String? _status;

  @override
  void dispose() {
    _provider.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Connect an AI provider", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Pick one provider and paste an API key. You can add more later in Settings."),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: _provider,
            builder: (_, v, __) {
              return Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: v,
                  items: const [
                    DropdownMenuItem(value: 'openai', child: Text('OpenAI (ChatGPT)')),
                    DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                    DropdownMenuItem(value: 'xai', child: Text('xAI Grok')),
                    DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek')),
                  ],
                  onChanged: (nv) => _provider.value = nv!,
                  decoration: const InputDecoration(labelText: 'Provider'),
                )),
                const SizedBox(width: 12),
                TextButton(onPressed: _openHowTo, child: const Text("How to get key"))
              ]);
            }
          ),
          const SizedBox(height: 8),
          Form(
            key: _form,
            child: TextFormField(
              controller: _keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "API Key",
                hintText: "Paste your API key",
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 10) ? "Please paste a valid key" : null,
            ),
          ),
          const SizedBox(height: 12),
          if (_status != null) Text(_status!, style: const TextStyle(color: Colors.green)),
          const Spacer(),
          Row(
            children: [
              Expanded(child: OutlinedButton(
                onPressed: _saving ? null : widget.onDone,
                child: const Text("Skip for now"),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _saving ? null : _saveLocal,
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Save & continue"),
              )),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _openHowTo() async {
    final p = _provider.value;
    final uri = switch (p) {
      'openai' => Uri.parse('https://platform.openai.com/account/api-keys'),
      'gemini' => Uri.parse('https://aistudio.google.com/app/apikey'),
      'xai' => Uri.parse('https://console.x.ai/'),
      'deepseek' => Uri.parse('https://platform.deepseek.com/api_keys'),
      _ => Uri.parse('https://example.com'),
    };
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveLocal() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _status = null; });
    final key = _keyCtrl.text.trim();
    final p = _provider.value;
    await LlmKeys.save(
      provider: p,
      openai: p == 'openai' ? key : null,
      gemini: p == 'gemini' ? key : null,
      xai: p == 'xai' ? key : null,
      deepseek: p == 'deepseek' ? key : null,
    );
    setState(() { _saving = false; _status = "Saved to this device."; });
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onDone();
  }
}
