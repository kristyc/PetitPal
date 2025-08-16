import 'package:flutter/material.dart';

class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug Menu")),
      body: ListView(
        children: const [
          ListTile(title: Text("Toggle Analytics")),
          ListTile(title: Text("Simulate Network Loss")),
          ListTile(title: Text("Force Provider Timeout")),
        ],
      ),
    );
  }
}
