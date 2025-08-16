import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy; // for ChangeNotifier
import 'src/analytics/analytics.dart';
import 'src/analytics/sentry_boot.dart';
import 'src/theme/registry.dart';
import 'src/onboarding/onboarding_flow.dart';
import 'src/voice/voice_screen.dart';
import 'config/launch_config.dart';

class PetitPalApp extends StatelessWidget {
  const PetitPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController();
    return legacy.ChangeNotifierProvider.value(
      value: controller,
      child: Builder(builder: (context) {
        final choice = controller.choice;
        return MaterialApp(
          title: 'PetitPal',
          debugShowCheckedModeBanner: !LaunchConfig.isProductionReady,
          theme: choice.lightTheme,
          darkTheme: choice.darkTheme,
          themeMode: choice.mode,
          routes: {
            '/home': (_) => const VoiceScreen(),
          },
          home: OnboardingGate(home: const VoiceScreen(), themeController: controller),
        );
      }),
    );
  }
}
