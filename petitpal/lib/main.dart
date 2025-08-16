import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:io';

// Import providers
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/family_provider.dart';

// Import services
import 'core/services/analytics_service.dart' as analytics;

// Import config
import 'config/internal_config.dart';

// Import screens
import 'src/onboarding/onboarding_screen.dart';
import 'src/home/home_screen.dart';
import 'src/theme/theme_preview_screen.dart';
import 'src/providers/providers_screen.dart';
import 'src/family/family_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase conditionally
  await _initializeFirebase();

  // Initialize analytics
  await analytics.AnalyticsService().initialize();

  runApp(const ProviderScope(child: PetitPalApp()));
}

// Initialize Firebase only if google-services.json exists and config allows it
Future<void> _initializeFirebase() async {
  try {
    // Check if Firebase should be initialized
    if (InternalConfig.analyticsEnabled || InternalConfig.crashlyticsEnabled) {
      // On Android, check if google-services.json exists
      // On other platforms, Firebase.apps will be empty if not configured
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized successfully');
      }
    } else {
      debugPrint('📊 Firebase disabled via config (LAUNCH_MODE = false)');
    }
  } catch (e) {
    // This is expected when google-services.json doesn't exist
    debugPrint('ℹ️ Firebase not configured (missing google-services.json): $e');
    debugPrint('   App will work without Firebase - add google-services.json to enable');
  }
}

class PetitPalApp extends ConsumerStatefulWidget {
  const PetitPalApp({super.key});

  @override
  ConsumerState<PetitPalApp> createState() => _PetitPalAppState();
}

class _PetitPalAppState extends ConsumerState<PetitPalApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Track app open
    await Analytics.appOpen();

    // Load app state
    await ref.read(appProvider.notifier).initialize();
    
    // Load theme
    await ref.read(themeProvider.notifier).loadTheme();
    
    // Load family data if available
    await ref.read(familyProvider.notifier).loadFamily();
  }

  Future<void> _initDeepLinks() async {
    try {
      // Listen for incoming links when app is already running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint('🔗 Deep link received: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('❌ Deep link error: $err');
        },
      );

      // Check if app was launched from a deep link
      // Note: This is the correct way to get initial link in app_links 6.x
      await _checkInitialLink();
    } catch (e) {
      debugPrint('❌ Deep link initialization failed: $e');
    }
  }

  Future<void> _checkInitialLink() async {
    try {
      // For app_links 6.x, initial links are handled through the stream
      // We just need to make sure we're listening from the start
      // The stream will emit any initial link automatically
      debugPrint('🔗 Deep link listener initialized');
    } catch (e) {
      debugPrint('❌ Error setting up initial link checking: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    final path = uri.path;
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;

    // Track deep link usage
    analytics.Analytics.deepLinkOpened(path);

    if (path.startsWith('/invite/') && token != null) {
      _handleFamilyInvite(token);
    } else {
      debugPrint('⚠️ Unknown deep link pattern: $uri');
    }
  }

  void _handleFamilyInvite(String token) {
    // Check if onboarding is complete
    final appState = ref.read(appProvider);
    
    if (!appState.isOnboardingComplete) {
      // Store the invite token to process after onboarding
      ref.read(familyProvider.notifier).setPendingInviteToken(token);
      debugPrint('📝 Stored invite token for after onboarding: $token');
    } else {
      // Process invite immediately
      _processInviteToken(token);
    }
  }

  void _processInviteToken(String token) {
    ref.read(familyProvider.notifier).acceptInvite(token).then((success) {
      if (mounted) {
        final message = success 
            ? 'Successfully joined family!' 
            : 'Failed to join family. Please try again.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          // Navigate to family screen to show the new family
          Navigator.of(context).pushNamed('/family');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final appState = ref.watch(appProvider);

    return MaterialApp(
      title: 'PetitPal',
      theme: themeState.currentTheme,
      debugShowCheckedModeBanner: !InternalConfig.isProductionReady,
      
      // Initial route based on onboarding status
      initialRoute: appState.isOnboardingComplete ? '/home' : '/onboarding',
      
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/themes': (context) => const ThemePreviewScreen(),
        '/providers': (context) => const ProvidersScreen(),
        '/family': (context) => const FamilyScreen(),
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('The requested page could not be found.'),
            ),
          ),
        );
      },

      // Global navigation observer for analytics
      navigatorObservers: [
        _AnalyticsNavigatorObserver(),
      ],
    );
  }
}

// Navigator observer for tracking screen views
class _AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      analytics.Analytics.track('screen_view', params: {
        'screen_name': route.settings.name!,
      });
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      analytics.Analytics.track('screen_view', params: {
        'screen_name': newRoute!.settings.name!,
      });
    }
  }
}