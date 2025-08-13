import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/keystore.dart';
import '../worker_api/worker_api.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ProviderSetupScreen extends StatefulWidget {
  const ProviderSetupScreen({super.key});
  @override
  State<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends State<ProviderSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _openai = TextEditingController();
  final _gemini = TextEditingController();
  final _grok = TextEditingController();
  final _deepseek = TextEditingController();
  bool _backingUp = false;
  String? _status;

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) { id = const Uuid().v4(); await prefs.setString('device_id', id); }
    return id;
  }

  Future<void> _saveAndBackup() async {
    if (!_form.currentState!.validate()) return;
    setState(()=>_backingUp=true);
    try {
      final keys = {
        'openai': _openai.text.trim(),
        'gemini': _gemini.text.trim(),
        'grok': _grok.text.trim(),
        'deepseek': _deepseek.text.trim(),
      };
      final cipher = await Keystore.encrypt(jsonEncode(keys));
      final deviceId = await _deviceId();
      await WorkerApi.saveEncryptedBackup(deviceId, cipher);
      setState(()=>_status='Saved and backed up securely.');
    } catch (e) {
      setState(()=>_status='Error: $e');
    } finally {
      setState(()=>_backingUp=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Providers')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              _field('OpenAI API Key', _openai),
              _field('Gemini API Key', _gemini),
              _field('Grok API Key', _grok),
              _field('DeepSeek API Key', _deepseek),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _backingUp?null:_saveAndBackup, child: Text(_backingUp?'Saving...':'Save & Backup to Cloudflare KV')),
              if (_status!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_status!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v)=> (v==null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}
