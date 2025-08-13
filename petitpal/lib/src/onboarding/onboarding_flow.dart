import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_preview_screen.dart';
import '../providers/provider_setup.dart';
import '../family/invite.dart';
import '../family/accept_invite.dart';
import '../../config/strings_config.dart';

class OnboardingGate extends StatefulWidget {
  final Widget home;
  final ThemeController themeController;
  const OnboardingGate({super.key, required this.home, required this.themeController});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _done;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(()=>_done = prefs.getBool('onboarded') ?? false);
  }

  Future<void> _setDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    setState(()=>_done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_done == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_done == true) return widget.home;
    return _OnboardingFlow(onFinished: _setDone, controller: widget.themeController);
  }
}

class _OnboardingFlow extends StatefulWidget {
  final VoidCallback onFinished;
  final ThemeController controller;
  const _OnboardingFlow({required this.onFinished, required this.controller});

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  int _step = 0;

  void _next() => setState(()=>_step++);

  @override
  Widget build(BuildContext context) {
    final steps = [
      _WelcomeStep(onNext: _next),
      _ThemeStep(controller: widget.controller, onNext: _next),
      _InviteStep(onNext: _next),
      _ProviderStep(onNext: _next),
      _TestStep(onFinish: widget.onFinished),
    ];
    return steps[_step];
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(StringsConfig.welcomeTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(StringsConfig.welcomeBody),
            const Spacer(),
            ElevatedButton(onPressed: onNext, child: const Text(StringsConfig.continueLabel)),
          ],
        ),
      ),
    );
  }
}

class _ThemeStep extends StatelessWidget {
  final ThemeController controller;
  final VoidCallback onNext;
  const _ThemeStep({required this.controller, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Theme')),
      body: ThemePreviewScreen(controller: controller),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(onPressed: onNext, child: const Text(StringsConfig.next)),
      ),
    );
  }
}

class _InviteStep extends StatelessWidget {
  final VoidCallback onNext;
  const _InviteStep({required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join or Invite Family')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('If someone sent you a PetitPal invite link or QR, tap Accept to join automatically.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_)=>const AcceptInviteScreen())), child: const Text('Accept Invite (Scan QR)')),
            const Divider(height: 32),
            const Text('Or create an invite for a family member to connect with you.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_)=>const InviteFamilyScreen())), child: const Text('Create an Invite QR')),
            const Spacer(),
            ElevatedButton(onPressed: onNext, child: const Text(StringsConfig.next)),
          ],
        ),
      ),
    );
  }
}

class _ProviderStep extends StatelessWidget {
  final VoidCallback onNext;
  const _ProviderStep({required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect AI Providers')),
      body: const ProviderSetupScreen(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(onPressed: onNext, child: const Text(StringsConfig.next)),
      ),
    );
  }
}

class _TestStep extends StatelessWidget {
  final VoidCallback onFinish;
  const _TestStep({required this.onFinish});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try Your First Question')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Tap the button and say a short question. End by saying “OKAY DONE”.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: ()=>Navigator.of(context).pushReplacementNamed('/home'), child: const Text('Open Voice Screen')),
            const Spacer(),
            ElevatedButton(onPressed: onFinish, child: const Text(StringsConfig.finishSetup)),
          ],
        ),
      ),
    );
  }
}
