import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FamilyHub extends StatefulWidget {
  const FamilyHub({super.key});
  @override State<FamilyHub> createState() => _FamilyHubState();
}

class _FamilyHubState extends State<FamilyHub> {
  final _inviteCode = "family-demo-code-1234"; // TODO replace with real code from Worker
  final _codeCtrl = TextEditingController();
  String _status = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Invite a family member"),
          const SizedBox(height: 8),
          Center(child: QrImageView(data: _inviteCode, size: 180)),
          const SizedBox(height: 8),
          const Text("Or paste code you received:"),
          Row(children: [
            Expanded(child: TextField(controller: _codeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Paste code"))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _join, child: const Text("Join")),
          ]),
          const SizedBox(height: 8),
          if (_status.isNotEmpty) Text(_status),
          const Divider(height: 32),
          const Text("Family members (demo)"),
          const ListTile(leading: Icon(Icons.person), title: Text("You")),
          // TODO: populate from Worker in B2
        ]),
      ),
    );
  }

  Future<void> _join() async {
    setState(() => _status = "Joined (stub).");
  }
}
