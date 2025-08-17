import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../config/internal_config.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;
  bool _firebaseAvailable = false;

  // Initialize analytics services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if Firebase is available and configured
      _firebaseAvailable = Firebase.apps.isNotEmpty;
      
      if (_firebaseAvailable && InternalConfig.analyticsEnabled) {
        _analytics = FirebaseAnalytics.instance;
        await _analytics?.setAnalyticsCollectionEnabled(true);
        
        if (kDebugMode) {
          print('✅ Firebase Analytics initialized');
        }
      }

      if (_firebaseAvailable && InternalConfig.crashlyticsEnabled) {
        _crashlytics = FirebaseCrashlytics.instance;
        await _crashlytics?.setCrashlyticsCollectionEnabled(true);
        
        // Set up automatic crash collection
        FlutterError.onError = _crashlytics!.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics!.recordError(error, stack, fatal: true);
          return true;
        };

        if (kDebugMode) {
          print('✅ Firebase Crashlytics initialized');
        }
      }

      if (!_firebaseAvailable) {
        if (kDebugMode) {
          print('ℹ️ Firebase not available - analytics will use debug logging only');
          print('   Add google-services.json and set LAUNCH_MODE=true to enable Firebase');
        }
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics initialization failed: $e');
      }
    }
  }

  // Track events
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    if (!InternalConfig.analyticsEnabled) return;
    
    if (_firebaseAvailable && _analytics != null) {
      try {
        await _analytics!.logEvent(
          name: eventName,
          parameters: parameters?.map((key, value) => MapEntry(key, value.toString())),
        );
        
        if (kDebugMode) {
          print('📊 Analytics event: $eventName ${parameters != null ? 'with params: $parameters' : ''}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to track event $eventName: $e');
        }
      }
    } else {
      // Fallback to debug logging when Firebase not available
      if (kDebugMode) {
        print('📊 DEBUG EVENT: $eventName ${parameters != null ? 'with params: $parameters' : ''}');
      }
    }
  }

  // Set user properties
  Future<void> setUserProperty(String name, String? value) async {
    if (!InternalConfig.analyticsEnabled) return;

    if (_firebaseAvailable && _analytics != null) {
      try {
        await _analytics!.setUserProperty(name: name, value: value);
        
        if (kDebugMode) {
          print('👤 User property set: $name = $value');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to set user property $name: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('👤 DEBUG USER PROPERTY: $name = $value');
      }
    }
  }

  // Set user ID (anonymous device ID)
  Future<void> setUserId(String? userId) async {
    if (!InternalConfig.analyticsEnabled) return;

    if (_firebaseAvailable && _analytics != null) {
      try {
        await _analytics!.setUserId(id: userId);
        
        if (kDebugMode) {
          print('🆔 User ID set: $userId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to set user ID: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('🆔 DEBUG USER ID: $userId');
      }
    }
  }

  // Log non-fatal errors
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason}) async {
    if (!InternalConfig.crashlyticsEnabled) return;

    if (_firebaseAvailable && _crashlytics != null) {
      try {
        await _crashlytics!.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: false,
        );
        
        if (kDebugMode) {
          print('🔥 Error logged to Crashlytics: $error');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to log error to Crashlytics: $e');
        }
      }
    } else {
      // Fallback to debug logging when Firebase not available
      if (kDebugMode) {
        print('🔥 DEBUG ERROR: $error');
        if (stackTrace != null) {
          print('Stack trace: $stackTrace');
        }
      }
    }
  }

  // Log custom messages
  Future<void> log(String message) async {
    if (!InternalConfig.crashlyticsEnabled) return;

    if (_firebaseAvailable && _crashlytics != null) {
      try {
        await _crashlytics!.log(message);
        
        if (kDebugMode) {
          print('📝 Crashlytics log: $message');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to log message: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('📝 DEBUG LOG: $message');
      }
    }
  }

  // Set custom keys for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!InternalConfig.crashlyticsEnabled) return;

    if (_firebaseAvailable && _crashlytics != null) {
      try {
        if (value is String) {
          await _crashlytics!.setCustomKey(key, value);
        } else if (value is int) {
          await _crashlytics!.setCustomKey(key, value);
        } else if (value is bool) {
          await _crashlytics!.setCustomKey(key, value);
        } else if (value is double) {
          await _crashlytics!.setCustomKey(key, value);
        } else {
          await _crashlytics!.setCustomKey(key, value.toString());
        }
        
        if (kDebugMode) {
          print('🔑 Custom key set: $key = $value');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to set custom key $key: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('🔑 DEBUG CUSTOM KEY: $key = $value');
      }
    }
  }

  // Common app events
  Future<void> trackAppOpen() async {
    await trackEvent('app_open');
  }

  Future<void> trackOnboardingStart() async {
    await trackEvent('onboarding_start');
  }

  Future<void> trackOnboardingComplete() async {
    await trackEvent('onboarding_complete');
  }

  Future<void> trackThemeSelected(String themeId) async {
    await trackEvent('theme_selected', parameters: {'theme_id': themeId});
  }

  Future<void> trackQuestionAsked(String model, int questionLength) async {
    await trackEvent('question_asked', parameters: {
      'model': model,
      'question_length': questionLength,
    });
  }

  Future<void> trackTtsSpoken(String model, int responseLength) async {
    await trackEvent('tts_spoken', parameters: {
      'model': model,
      'response_length': responseLength,
    });
  }

  Future<void> trackModelAutoSwitch(String fromModel, String toModel, String trigger) async {
    await trackEvent('model_auto_switch', parameters: {
      'from_model': fromModel,
      'to_model': toModel,
      'trigger': trigger,
    });
  }

  Future<void> trackFamilyInviteCreated() async {
    await trackEvent('family_invite_created');
  }

  Future<void> trackFamilyInviteJoined(String method) async {
    await trackEvent('family_invite_joined', parameters: {'method': method});
  }

  Future<void> trackProviderRequestFailed(String provider, String error) async {
    await trackEvent('provider_request_failed', parameters: {
      'provider': provider,
      'error_type': error,
    });
  }

  Future<void> trackSpeechRecognitionError(String error) async {
    await trackEvent('speech_recognition_error', parameters: {
      'error_type': error,
    });
  }

  Future<void> trackVoiceInteractionStart() async {
    await trackEvent('voice_interaction_start');
  }

  Future<void> trackVoiceInteractionComplete(bool successful) async {
    await trackEvent('voice_interaction_complete', parameters: {
      'successful': successful,
    });
  }

  Future<void> trackProviderKeyAdded(String provider) async {
    await trackEvent('provider_key_added', parameters: {
      'provider': provider,
    });
  }

  Future<void> trackDeepLinkOpened(String linkType) async {
    await trackEvent('deep_link_opened', parameters: {
      'link_type': linkType,
    });
  }

  // Debug helper - only works in debug mode
  void debugEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      print('🐛 DEBUG EVENT: $eventName ${parameters != null ? 'with params: $parameters' : ''}');
    }
  }
}

// Convenience methods for common analytics operations
class Analytics {
  static final _service = AnalyticsService();

  static Future<void> initialize() => _service.initialize();
  static Future<void> track(String event, {Map<String, dynamic>? params}) => 
      _service.trackEvent(event, parameters: params);
  static Future<void> error(dynamic error, StackTrace? stack, {String? reason}) => 
      _service.logError(error, stack, reason: reason);
  static Future<void> setUserId(String? id) => _service.setUserId(id);
  static Future<void> setUserProperty(String name, String? value) => 
      _service.setUserProperty(name, value);

  // Quick access to common events
  static Future<void> appOpen() => _service.trackAppOpen();
  static Future<void> onboardingStart() => _service.trackOnboardingStart();
  static Future<void> onboardingComplete() => _service.trackOnboardingComplete();
  static Future<void> themeSelected(String theme) => _service.trackThemeSelected(theme);
  static Future<void> questionAsked(String model, int length) => 
      _service.trackQuestionAsked(model, length);
  static Future<void> modelAutoSwitch(String from, String to, String trigger) => 
      _service.trackModelAutoSwitch(from, to, trigger);
  static Future<void> familyInviteCreated() => _service.trackFamilyInviteCreated();
  static Future<void> familyInviteJoined(String method) => 
      _service.trackFamilyInviteJoined(method);
  static Future<void> deepLinkOpened(String type) => _service.trackDeepLinkOpened(type);
}