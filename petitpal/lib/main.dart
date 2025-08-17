import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/diagnostics_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PetitPalApp()));
}

class PetitPalApp extends StatelessWidget {
  const PetitPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetitPal',
      debugShowCheckedModeBanner: false,
      theme: highContrastDarkTheme(),
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/diagnostics': (_) => const DiagnosticsScreen(),
      },
    );
  }
}
