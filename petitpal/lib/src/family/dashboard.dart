import 'package:flutter/material.dart';

class FamilyDashboardScreen extends StatelessWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: GET /api/family/list and render members
    return Scaffold(
      appBar: AppBar(title: const Text("Family")),
      body: const Center(child: Text("Members will appear here")),
    );
  }
}
