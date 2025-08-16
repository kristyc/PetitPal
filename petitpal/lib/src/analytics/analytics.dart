import 'package:sentry_flutter/sentry_flutter.dart';
import '../../config/internal_config.dart';

class PetitAnalytics {
  static Future<void> bootstrap() async {
    if (InternalConfig.sentryEnabled && InternalConfig.sentryDsn.isNotEmpty) {
      await SentryFlutter.init((o) { o.dsn = InternalConfig.sentryDsn; });
    }
  }
  static Future<void> log(String name, [Map<String, Object?> params = const {}]) async {}
}
