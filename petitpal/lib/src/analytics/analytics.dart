class Analytics {
  static bool enabled = false;
  static void init({required bool enable}) { enabled = enable; }
  static void logEvent(String name, Map<String, Object?> params) {
    if (!enabled) return;
    // TODO: integrate Firebase Analytics
  }
}
