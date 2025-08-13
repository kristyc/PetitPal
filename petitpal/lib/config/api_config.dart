enum ApiEnvironment { dev, staging, prod }

class ApiConfig {
  static late ApiEnvironment _env;
  static void setEnvironment(ApiEnvironment env) => _env = env;

  static String get baseUrl {
    switch (_env) {
      case ApiEnvironment.dev:
        return 'https://petitpal-api.kristyc.workers.dev';
      case ApiEnvironment.staging:
        return 'https://petitpal-api.kristyc.workers.dev?env=staging';
      case ApiEnvironment.prod:
        return 'https://petitpal-api.kristyc.workers.dev';
    }
  }

  static const int timeoutSeconds = 20;
  static const int workerTimeoutSeconds = 30;
  static const int appRetries = 3;
}
