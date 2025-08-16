import 'package:flutter/material.dart';

class ProviderSetupScreen extends StatefulWidget {
  const ProviderSetupScreen({super.key});

  @override
  State<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends State<ProviderSetupScreen> {
  final openaiCtrl = TextEditingController();
  final geminiCtrl = TextEditingController();
  final grokCtrl = TextEditingController();
  final deepseekCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Setup")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Enter one or more API keys. You can add others later."),
          _field("OpenAI (ChatGPT)", openaiCtrl),
          _field("Gemini (Google)", geminiCtrl),
          _field("Grok (xAI)", grokCtrl),
          _field("DeepSeek", deepseekCtrl),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Validate and store locally; also push encrypted backup via Worker
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      obscureText: true,
    ),
  );
}
