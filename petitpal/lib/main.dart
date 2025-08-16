import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'config/launch_config.dart';
import 'config/theme_config.dart';
import 'config/strings_config.dart';
import 'src/voice/voice_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/family_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const ProviderScope(
      child: PetitPalApp(),
    ),
  );
}

class PetitPalApp extends ConsumerStatefulWidget {
  const PetitPalApp({super.key});

  @override
  ConsumerState<PetitPalApp> createState() => _PetitPalAppState();
}

class _PetitPalAppState extends ConsumerState<PetitPalApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  void _initializeDeepLinks() {
    _appLinks = AppLinks();
    
    // Handle app launch from deep link
    _appLinks.getInitialAppLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
    
    // Handle deep links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'petitpal' && uri.host == 'invite') {
      final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (token != null) {
        _handleFamilyInvite(token);
      }
    }
  }

  void _handleFamilyInvite(String token) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(StringsConfig.processing),
          ],
        ),
      ),
    );

    // Accept the invite
    ref.read(familyProvider.notifier).acceptInvite(token).then((success) {
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(StringsConfig.familyConnected),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join family. The invite may be expired.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: StringsConfig.appTitle,
      debugShowCheckedModeBanner: LaunchConfig.showDebugBanner,
      
      // Themes
      theme: AppThemeConfig.lightTheme,
      darkTheme: AppThemeConfig.darkTheme,
      themeMode: themeMode,
      
      // Accessibility - ensure minimum text scale for seniors
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 2.0)
            ),
          ),
          child: child!,
        );
      },
      
      home: const VoiceScreen(),
      
      // Error handling
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const VoiceScreen(),
        );
      },
    );
  }
}
