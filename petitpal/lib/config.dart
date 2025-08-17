/// Centralized config for PetitPal.
class AppConfig {
  /// Cloudflare Worker (production)
  static const String workerBaseUrl = 'https://petitpal-api.kristyc.workers.dev';
  static const String workerFilename = 'https://petitpal-api.kristyc.workers.dev/worker.js';

  /// Cloudflare KV (future use)
  /// Namespace: petitpal-kv
  /// Binding variable name: petitpal-kv
  static const String kvNamespace = 'petitpal-kv';
  static const String kvBinding = 'petitpal-kv';

  /// Default model used by the Worker for chat/transcription.
  static const String defaultModel = 'gpt-4o-mini';

  /// Returns the base URL without trailing slashes and without '/worker.js'.
  static String get normalizedWorkerBaseUrl {
    var url = workerBaseUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (url.endsWith('/worker.js')) {
      url = url.substring(0, url.length - '/worker.js'.length);
    }
    return url;
  }
}
