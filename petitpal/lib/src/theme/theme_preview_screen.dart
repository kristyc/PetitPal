import 'package:flutter/material.dart';
import 'registry.dart';

class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themes = themesRegistry();
    return Scaffold(
      appBar: AppBar(title: const Text("Theme Preview")),
      body: ListView.builder(
        itemCount: themes.length,
        itemBuilder: (ctx, i) {
          final t = themes[i];
          return Card(
            child: ListTile(
              title: Text(t.name),
              subtitle: Text(t.shortDescription),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: apply theme at runtime & persist selection
                },
                child: const Text("Try this theme"),
              ),
            ),
          );
        },
      ),
    );
  }
}
