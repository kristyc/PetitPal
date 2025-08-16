# Build Config

- Flutter: latest stable.
- Android: Embedding v2, NDK `27.0.12077973`.
- Packages: `speech_to_text`, `flutter_tts`, `permission_handler`, `http`, `flutter_secure_storage`, `crypto`, `uuid`, `qr_flutter`, `qr_code_scanner`.
- Troubleshooting:
  - **Gradle hangs**: run with `--stacktrace --info` and ensure Java installed.
  - **JS dependency version conflicts**: align `js` versions (see pubspec).
