import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final bool isOnboardingComplete;
  final bool isFirstLaunch;
  final String? deviceId;

  const AppState({
    this.isOnboardingComplete = false,
    this.isFirstLaunch = true,
    this.deviceId,
  });

  AppState copyWith({
    bool? isOnboardingComplete,
    bool? isFirstLaunch,
    String? deviceId,
  }) {
    return AppState(
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState());

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final isFirstLaunch = prefs.getBool('first_launch') ?? true;
      final deviceId = prefs.getString('device_id') ?? _generateDeviceId();

      // Save device ID if it's new
      if (!prefs.containsKey('device_id')) {
        await prefs.setString('device_id', deviceId);
      }

      state = AppState(
        isOnboardingComplete: isOnboardingComplete,
        isFirstLaunch: isFirstLaunch,
        deviceId: deviceId,
      );
    } catch (e) {
      print('Error initializing app state: $e');
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      await prefs.setBool('first_launch', false);
      
      state = state.copyWith(
        isOnboardingComplete: true,
        isFirstLaunch: false,
      );
    } catch (e) {
      print('Error completing onboarding: $e');
    }
  }

  String _generateDeviceId() {
    // Generate a simple device ID - in production, you might want something more robust
    return 'device_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).round()}';
  }
}

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});
