class LaunchConfig {
  // CRITICAL: Set to true before production launch
  static const bool isProductionReady = false;
  
  // Analytics (disabled in development)
  static bool get analyticsEnabled => isProductionReady;
  static bool get crashlyticsEnabled => isProductionReady;
  static bool get sentryEnabled => isProductionReady;
  
  // API Configuration
  static String get workerBaseUrl => isProductionReady 
      ? 'https://petitpal-api.kristyc.workers.dev'
      : 'https://dev-petitpal-api.kristyc.workers.dev';
  
  // Feature Flags
  static const bool enableHotwordDetection = true;
  static const bool enableFamilySharing = true;
  static const bool enableMultipleLLMs = true;
  static const bool enableVoiceOnboarding = true;
  static const bool enablePremiumAnimations = true;
  
  // Debug Features (only in development)
  static bool get showDebugBanner => !isProductionReady;
  static bool get enableDebugMenu => !isProductionReady;
  static bool get verboseLogging => !isProductionReady;
}