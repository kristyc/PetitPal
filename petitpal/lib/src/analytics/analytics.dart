import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../config/launch_config.dart';
import '../../config/analytics_events.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

class AnalyticsService {
  bool _inited = false;

  Future<void> initIfNeeded() async {
    if (_inited) return;
    if (LaunchConfig.analyticsEnabled || LaunchConfig.crashlyticsEnabled) {
      try {
        await Firebase.initializeApp();
        if (LaunchConfig.crashlyticsEnabled) {
          FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        }
      } catch (_) {}
    }
    _inited = true;
  }

  Future<void> log(AnalyticsEvent e, {Map<String, Object?>? params}) async {
    if (!LaunchConfig.analyticsEnabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: e.name, parameters: params);
    } catch (_) {}
  }
}
