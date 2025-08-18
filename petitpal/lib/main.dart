import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/diagnostics_screen.dart';
import 'widgets/mic_widget_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow taps on the Android homescreen widget to reach Dart
  await MicWidget.initBackground();

  runApp(const ProviderScope(child: PetitPalApp()));
}


class PetitPalApp extends StatelessWidget {
  const PetitPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: AppTheme.dark(), 
      title: 'PetitPal',
      debugShowCheckedModeBanner: false,
      
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/diagnostics': (_) => const DiagnosticsScreen(),
      },
    );
  }
}
