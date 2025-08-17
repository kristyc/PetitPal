class DefaultFirebaseOptions {
  static get currentPlatform => throw UnsupportedError(
    'Firebase not configured. Please run `flutterfire configure` to set up Firebase, '
    'or set LAUNCH_MODE = false in internal_config.dart to run without Firebase.'
  );
}