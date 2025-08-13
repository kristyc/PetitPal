import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../worker_api/worker_api.dart';

class InviteFamilyScreen extends StatefulWidget {
  const InviteFamilyScreen({super.key});
  @override
  State<InviteFamilyScreen> createState() => _InviteFamilyScreenState();
}

class _InviteFamilyScreenState extends State<InviteFamilyScreen> {
  final _name = TextEditingController(text: 'Family Member');
  String? _deeplink;

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) { id = const Uuid().v4(); await prefs.setString('device_id', id); }
    return id;
  }

  Future<void> _create() async {
    final deviceId = await _deviceId();
    final res = await WorkerApi.createInvite(deviceId, _name.text.trim());
    setState(()=>_deeplink = res['deeplink'] as String);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite a Family Member')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Member name')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _create, child: const Text('Generate Invite')),
            const SizedBox(height: 24),
            if (_deeplink!=null) ...[
              SelectableText(_deeplink!, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              QrImageView(data: _deeplink!, version: QrVersions.auto, size: 220),
            ]
          ],
        ),
      ),
    );
  }
}
