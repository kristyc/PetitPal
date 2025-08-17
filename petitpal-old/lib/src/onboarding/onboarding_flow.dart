import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../theme/themes.dart';
import '../voice/voice_helpers.dart';
import 'provider_setup_step.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int step = 0;
  @override
  void initState() {
    super.initState();
    VoiceHelpers.speak("Welcome to PetitPal! Let's pick how the app should look.");
  }

  @override
  Widget build(BuildContext context) {
    final themeCtl = ref.watch(themeControllerProvider);
    final steps = <Widget>[
      _ThemeStep(onPick: (id) => themeCtl.switchTheme(id), onContinue: () => setState(() => step++)),
      ProviderSetupStep(onDone: () => setState(() => step++)),
      _FinishStep(onFinish: () async {
        await ref.read(markOnboardingDoneProvider)();
        if (mounted) context.go('/home');
      }),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: steps[step]),
    );
  }
}

class _ThemeStep extends ConsumerWidget {
  final void Function(String id) onPick;
  final VoidCallback onContinue;
  const _ThemeStep({required this.onPick, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeCtl = ref.watch(themeControllerProvider);
    final themes = const [
      ['high_contrast_light', 'High Contrast Light'],
      ['high_contrast_dark', 'High Contrast Dark'],
      ['modern_light', 'Modern Light'],
      ['modern_dark', 'Modern Dark'],
      ['modern_elegant', 'Modern Elegant'],
      ['vibrant_contemporary', 'Vibrant Contemporary'],
      ['warm_minimalist', 'Warm Minimalist'],
      ['large_text_friendly', 'Large Text Friendly'],
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Choose a theme:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(child: ListView.builder(itemCount: themes.length, itemBuilder: (_, i) {
          final id = themes[i][0]; final name = themes[i][1];
          return Card(child: ListTile(
            title: Text(name), subtitle: Text(id),
            trailing: themeCtl.currentId == id ? const Icon(Icons.check_circle) : null,
            onTap: () => onPick(id),
          ));
        })),
        ElevatedButton(onPressed: onContinue, child: const Text("Looks good, continue"))
      ]),
    );
  }
}

class _FinishStep extends StatelessWidget {
  final VoidCallback onFinish;
  const _FinishStep({required this.onFinish});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("All set!"),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: onFinish, child: const Text("Start using PetitPal")),
    ]));
  }
}
