import 'package:flutter/material.dart';

class AcceptInviteScreen extends StatelessWidget {
  const AcceptInviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Joining Family...")),
      body: const Center(
        child: Text("Processing deep link / QR ..."),
      ),
    );
  }
}
