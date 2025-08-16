import 'package:flutter/material.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text("Invite Family Member")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Member name (e.g., Mom, Dad, Sarah)"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: POST /api/family/create_invite and show QR & link
              },
              child: const Text("Create Invitation"),
            )
          ],
        ),
      ),
    );
  }
}
