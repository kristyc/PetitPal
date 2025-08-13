import 'package:flutter/material.dart';
import 'registry.dart';

class ThemePreviewScreen extends StatefulWidget {
  final ThemeController controller;
  const ThemePreviewScreen({super.key, required this.controller});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  String _selected = 'high_contrast_dark';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Preview')),
      body: ListView(
        children: [
          for (final id in [
            'high_contrast_light','high_contrast_dark','modern_light','modern_dark',
            'modern_elegant','vibrant_contemporary','warm_minimalist','large_text_friendly'
          ]) ListTile(
            title: Text(id.replaceAll('_',' ').toUpperCase()),
            trailing: Radio<String>(value: id, groupValue: _selected, onChanged: (v){ setState(()=>_selected=v!); }),
            onTap: () => setState(()=>_selected=id),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () { widget.controller.setTheme(_selected); Navigator.pop(context, _selected); },
          child: const Text('Use this theme'),
        ),
      ),
    );
  }
}
