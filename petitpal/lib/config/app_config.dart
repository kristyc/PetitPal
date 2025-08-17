/// Central app configuration and URL normalization.
/// Keep only frontend-safe values here.
class AppConfig {
  /// Cloudflare Worker base URL (no trailing slash).
  static const String workerBaseUrl = 'https://petitpal-api.kristyc.workers.dev';

  /// Optional metadata for reference.
  static const String workerFilename = 'https://petitpal-api.kristyc.workers.dev/worker.js';
  static const String kvNamespace = 'petitpal-kv';
  static const String kvNamespaceBinding = 'petitpal-kv';

  /// Returns the worker base normalized to exclude a trailing slash.
  static String get normalizedWorkerBaseUrl {
    var u = workerBaseUrl.trim();
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
