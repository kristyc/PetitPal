// Controls production toggles from one place.
class LaunchConfig {
  static const String envName = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const bool isProductionReady = bool.fromEnvironment('PROD_READY', defaultValue: false);

  static bool get analyticsEnabled => envName == 'prod' && isProductionReady;
  static bool get crashlyticsEnabled => envName == 'prod' && isProductionReady;
  static bool get sentryEnabled => envName != 'dev'; // enable for staging/prod
  static bool get debugOverlays => envName != 'prod';

  static const String mobileSentryDsn = 'https://564ee25c345784dc11c8261c53dd9a0a@o4509830944522240.ingest.de.sentry.io/4509831015366736';
}
