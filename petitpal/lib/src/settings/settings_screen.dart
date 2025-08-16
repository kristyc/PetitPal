import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/themes.dart';
import '../providers/llm_keys.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _selectedProvider;
  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final sp = await LlmKeys.selectedProvider();
    if (mounted) setState(() => _selectedProvider = sp ?? 'openai');
  }

  @override
  Widget build(BuildContext context) {
    final themeCtl = ref.watch(themeControllerProvider);
    final entries = const [
      ['high_contrast_light', 'High Contrast Light'],
      ['high_contrast_dark', 'High Contrast Dark'],
      ['modern_light', 'Modern Light'],
      ['modern_dark', 'Modern Dark'],
      ['modern_elegant', 'Modern Elegant'],
      ['vibrant_contemporary', 'Vibrant Contemporary'],
      ['warm_minimalist', 'Warm Minimalist'],
      ['large_text_friendly', 'Large Text Friendly'],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const ListTile(title: Text('Theme')),
          for (final e in entries)
            RadioListTile<String>(
              value: e[0], groupValue: themeCtl.currentId,
              onChanged: (v) => themeCtl.switchTheme(v!), title: Text(e[1])),
          const Divider(),
          ListTile(title: const Text('Default AI provider')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _selectedProvider ?? 'openai',
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI (ChatGPT)')),
                DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                DropdownMenuItem(value: 'xai', child: Text('xAI Grok')),
                DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek')),
              ],
              onChanged: (v) async {
                setState(() => _selectedProvider = v);
                await LlmKeys.save(provider: v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
