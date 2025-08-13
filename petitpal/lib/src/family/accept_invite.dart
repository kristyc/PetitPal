import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../worker_api/worker_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AcceptInviteScreen extends StatefulWidget {
  const AcceptInviteScreen({super.key});
  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  String? _status;

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) { id = const Uuid().v4(); await prefs.setString('device_id', id); }
    return id;
  }

  Future<void> _accept(String token) async {
    final deviceId = await _deviceId();
    try {
      final res = await WorkerApi.acceptInvite(deviceId, token);
      setState(()=>_status = "Joined family: ${res['family_id']} as ${res['member_name']}");
    } catch (e) {
      setState(()=>_status = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Invite QR')),
      body: Column(
        children: [
          Expanded(child: MobileScanner(onDetect: (cps) {
            final raw = cps.barcodes.first.rawValue ?? '';
            if (raw.startsWith('petitpal://invite/')) {
              final token = raw.split('/').last;
              _accept(token);
            }
          })),
          if (_status!=null) Padding(padding: const EdgeInsets.all(12), child: Text(_status!)),
        ],
      ),
    );
  }
}
