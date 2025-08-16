import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../config/internal_config.dart';

// App state model
class AppState {
  final bool isOnboardingComplete;
  final String deviceId;
  final bool isLoading;
  final String? error;
  final bool isFirstRun;
  final Map<String, dynamic> deviceInfo;

  AppState({
    this.isOnboardingComplete = false,
    this.deviceId = '',
    this.isLoading = false,
    this.error,
    this.isFirstRun = true,
    this.deviceInfo = const {},
  });

  AppState copyWith({
    bool? isOnboardingComplete,
    String? deviceId,
    bool? isLoading,
    String? error,
    bool? isFirstRun,
    Map<String, dynamic>? deviceInfo,
  }) {
    return AppState(
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      deviceId: deviceId ?? this.deviceId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}

// App provider notifier
class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(AppState());

  SharedPreferences? _prefs;

  // Initialize app state
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Initialize shared preferences
      _prefs = await SharedPreferences.getInstance();

      // Check if this is first run
      final isFirstRun = !(_prefs?.containsKey(InternalConfig.storageKeyOnboardingComplete) ?? false);

      // Get or create device ID
      final deviceId = await _getOrCreateDeviceId();

      // Check onboarding status
      final isOnboardingComplete = _prefs?.getBool(InternalConfig.storageKeyOnboardingComplete) ?? false;

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      state = state.copyWith(
        isFirstRun: isFirstRun,
        deviceId: deviceId,
        isOnboardingComplete: isOnboardingComplete,
        deviceInfo: deviceInfo,
        isLoading: false,
      );

      if (kDebugMode) {
        print('✅ App initialized:');
        print('   Device ID: $deviceId');
        print('   First Run: $isFirstRun');
        print('   Onboarding Complete: $isOnboardingComplete');
        print('   Device Info: $deviceInfo');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize app: ${e.toString()}',
      );
      
      if (kDebugMode) {
        print('❌ App initialization failed: $e');
      }
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    try {
      await _prefs?.setBool(InternalConfig.storageKeyOnboardingComplete, true);
      state = state.copyWith(isOnboardingComplete: true);
      
      if (kDebugMode) {
        print('✅ Onboarding completed');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to save onboarding status: ${e.toString()}');
    }
  }

  // Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    try {
      await _prefs?.setBool(InternalConfig.storageKeyOnboardingComplete, false);
      state = state.copyWith(isOnboardingComplete: false);
      
      if (kDebugMode) {
        print('🔄 Onboarding reset');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset onboarding: ${e.toString()}');
    }
  }

  // Get or create device ID
  Future<String> _getOrCreateDeviceId() async {
    String? deviceId = _prefs?.getString(InternalConfig.storageKeyDeviceId);
    
    if (deviceId == null || deviceId.isEmpty) {
      // Generate new device ID
      deviceId = _generateDeviceId();
      await _prefs?.setString(InternalConfig.storageKeyDeviceId, deviceId);
      
      if (kDebugMode) {
        print('🆔 Generated new device ID: $deviceId');
      }
    }
    
    return deviceId;
  }

  // Generate anonymous device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 997) % 999999; // Simple pseudo-random
    return 'device_${timestamp}_$random';
  }

  // Get device information for analytics
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final info = <String, dynamic>{};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info.addAll({
          'platform': 'android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info.addAll({
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
          'uuid': iosInfo.identifierForVendor,
        });
      }

      return info;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get device info: $e');
      }
      return {'platform': Platform.operatingSystem};
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Update device info (if needed)
  Future<void> refreshDeviceInfo() async {
    final deviceInfo = await _getDeviceInfo();
    state = state.copyWith(deviceInfo: deviceInfo);
  }

  // Check if app needs update (placeholder for future use)
  Future<bool> checkForUpdates() async {
    // TODO: Implement version checking logic
    return false;
  }

  // Debug methods
  void printDebugInfo() {
    if (kDebugMode) {
      print('🐛 App Debug Info:');
      print('   Device ID: ${state.deviceId}');
      print('   Onboarding Complete: ${state.isOnboardingComplete}');
      print('   First Run: ${state.isFirstRun}');
      print('   Loading: ${state.isLoading}');
      print('   Error: ${state.error}');
      print('   Device Info: ${state.deviceInfo}');
    }
  }

  // Clear all app data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      await _prefs?.clear();
      state = AppState(); // Reset to initial state
      
      if (kDebugMode) {
        print('🧹 All app data cleared');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear data: ${e.toString()}');
    }
  }
}

// Provider definition
final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});

// Convenience providers
final deviceIdProvider = Provider<String>((ref) {
  return ref.watch(appProvider).deviceId;
});

final isOnboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(appProvider).isOnboardingComplete;
});

final isFirstRunProvider = Provider<bool>((ref) {
  return ref.watch(appProvider).isFirstRun;
});

final deviceInfoProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(appProvider).deviceInfo;
});