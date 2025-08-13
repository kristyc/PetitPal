import 'package:sentry_flutter/sentry_flutter.dart';
import '../../config/launch_config.dart';

Future<void> bootSentry() async {
  if (!LaunchConfig.sentryEnabled) return;
  await SentryFlutter.init((o) {
    o.dsn = LaunchConfig.mobileSentryDsn;
    o.tracesSampleRate = 0.2;
    o.environment = LaunchConfig.envName;
  });
}
