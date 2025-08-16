import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/theme/theme_preview_screen.dart';
import '../features/providers/providers_screen.dart';
import '../features/family/family_screen.dart';
import '../providers/app_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isFirstRun = ref.watch(isFirstRunProvider);

  return GoRouter(
    initialLocation: isFirstRun ? '/onboarding' : '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/themes',
        builder: (context, state) => const ThemePreviewScreen(),
      ),
      GoRoute(
        path: '/providers',
        builder: (context, state) => const ProvidersScreen(),
      ),
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyScreen(),
      ),
      GoRoute(
        path: '/invite/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return FamilyScreen(inviteToken: token);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});