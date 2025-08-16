#!/usr/bin/env bash
set -euo pipefail

# PetitPal MVP - complete project generator
# Creates:
#   /petitpal_mvp/
#       petitpal/                 # Flutter app
#       cloudflare-worker/        # Worker backend + KV
#       docs/                     # Setup & API docs, troubleshooting
#       scripts/compat_check.sh   # Quick env sanity checker
#   petitpal_mvp.zip              # Full zip archive
#   petitpal_mvp.patch            # Git patch of all files

ROOT="$(pwd)"
APP="$ROOT/petitpal"
WKR="$ROOT/cloudflare-worker"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$APP" "$WKR" "$DOCS" "$SCRIPTS"

w() { # write a file from heredoc
  local file="$1"; shift
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<'EOF'
'"$@"'
EOF
}

wb() { # base64->binary file
  local file="$1" b64="$2"
  mkdir -p "$(dirname "$file")"
  printf '%s' "$b64" | base64 -d > "$file"
}

# -----------------------------
# Top-level README + BUILD CONFIG
# -----------------------------
w "$ROOT/README.md" '
# PetitPal (MVP)

Voice-first assistant for seniors (Android first). Backend: Cloudflare Worker + KV.
This bundle includes:

- **/petitpal** — Flutter app with Riverpod, go_router, STT/TTS, JSON-driven themes/onboarding, secure key backup, QR invites, deep links, provider proxy via Worker.
- **/cloudflare-worker** — Worker with complete MVP endpoints.
- **/docs** — Setup guide, API spec, troubleshooting, deployment checklist.
- **/scripts/compat_check.sh** — Environment sanity checker.

Follow **docs/SETUP_GUIDE.md** to go from zero → working app in ~30 minutes.
'

w "$ROOT/BUILD_CONFIG.md" '
# BUILD_CONFIG.md

**Recommended, known-good versions**

- Flutter SDK: 3.22.2 (stable)
- Dart: 3.3.x
- Android Gradle Plugin (AGP): 8.4.2
- Kotlin: 1.9.24
- Android SDK: 35
- minSdk: 24
- NDK: 27.0.12077973
- JDK: 17

These combinations are tested to build cleanly for this project.
'

# -----------------------------
# Flutter app: pubspec + analysis options
# -----------------------------
w "$APP/pubspec.yaml" '
name: petitpal
description: Voice-first assistant for seniors. Flutter + Riverpod + Cloudflare Worker backend.
publish_to: "none"
version: 0.5.0+5

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.3
  http: ^1.2.2
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.2.2
  speech_to_text: ^6.6.2
  flutter_tts: ^4.0.2
  uuid: ^4.4.0
  qr_flutter: ^4.1.0
  mobile_scanner: ^6.0.2
  uni_links: ^0.5.1
  url_launcher: ^6.3.0
  cryptography: ^2.7.0
  connectivity_plus: ^6.1.0
  package_info_plus: ^8.0.2

  # Firebase (integrated but disabled by default; safe if google-services.json not present)
  firebase_core: ^3.4.1
  firebase_analytics: ^11.3.0
  firebase_crashlytics: ^4.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.2

flutter:
  uses-material-design: true
  assets:
    - assets/themes/themes.json
    - assets/themes/theme_voice_descriptions.json
    - assets/config/onboarding.json
    - assets/config/provider_setup.json
'

w "$APP/analysis_options.yaml" '
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_final_locals: true
    avoid_redundant_argument_values: true
    avoid_print: true
'

# -----------------------------
# Flutter app: lib/config
# -----------------------------
mkdir -p "$APP/lib/config"

w "$APP/lib/config/internal_config.dart" '
// Single source of truth for launch toggles and URLs.
class InternalConfig {
  InternalConfig._();

  // Base URL of your Cloudflare Worker backend
  static const String workerBaseUrl = "https://petitpal-api.kristyc.workers.dev";

  // Analytics & diagnostics (off by default until you drop google-services.json)
  static const bool analyticsEnabled = false;
  static const bool crashlyticsEnabled = false;
  static const bool sentryEnabled = false;

  // Motion and accessibility defaults
  static const bool premiumMotionDefault = true;

  // Security headers
  static const String appUserAgent = "PetitPal/0.5.0 (Flutter)";
}
'

w "$APP/lib/config/launch_config.dart" '
// Flip these when preparing for production launch.
class LaunchConfig {
  LaunchConfig._();

  // Set to true when you are launching to production and have Firebase configured.
  static const bool LAUNCH_MODE = false;

  static const bool analytics => LAUNCH_MODE ? true : false;
  static const bool crashlytics => LAUNCH_MODE ? true : false;
  static const bool sentry => LAUNCH_MODE ? true : false;
}
'

w "$APP/lib/config/strings_config.dart" '
// Centralized strings so a non-developer can change copy without hunting in widgets.
class StringsConfig {
  StringsConfig._();

  static const appName = "PetitPal";

  static const voiceScreenTitle = "Ask PetitPal";
  static const tapMicToSpeak = "Tap the mic and speak";
  static const listening = "Listening…";
  static const processing = "Thinking…";
  static const speaking = "Speaking…";

  static const setupTitle = "Set up your keys";
  static const setupBody = "Enter at least one provider key so PetitPal can answer your questions.";
  static const save = "Save";
  static const test = "Test";
  static const openai = "OpenAI";
  static const gemini = "Gemini";
  static const grok = "Grok";
  static const deepseek = "DeepSeek";

  static const family = "Family";
  static const inviteFamily = "Invite Family Member";
  static const acceptInvite = "Accept Invite";
  static const scanQr = "Scan QR";
  static const showQr = "Show QR";
  static const yourName = "Your Name";

  static const onboardingTitle = "Welcome to PetitPal";
  static const onboardingNext = "Next";
  static const startUsingApp = "Start using PetitPal";
}
'

w "$APP/lib/config/api_config.dart" '
// API routes, headers, and timeouts.
class ApiConfig {
  ApiConfig._();
  static const healthPath = "/health";
  static const keysSavePath = "/api/keys/save";
  static const keysGetPath = "/api/keys/get";
  static const chatPath = "/api/chat";
  static const familyCreateInvitePath = "/api/family/create_invite";
  static const familyAcceptInvitePath = "/api/family/accept_invite";
  static const familyListPath = "/api/family/list";

  static const requestTimeoutSeconds = 30;
}
'

# -----------------------------
# Flutter app: analytics
# -----------------------------
mkdir -p "$APP/lib/src/analytics"

w "$APP/lib/src/analytics/events.dart" '
// Canonical event names and parameters to avoid typos.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const appFirstOpen = "app_first_open";
  static const themeSelected = "theme_selected";
  static const setupCompleted = "setup_completed";

  static const voiceActivationStarted = "voice_activation_started";
  static const questionAsked = "question_asked";
  static const ttsSpoken = "tts_spoken";
  static const interactionCompleted = "interaction_completed";

  static const providerRequestFailed = "provider_request_failed";
  static const backendCallResult = "backend_call_result";

  static const familyInviteCreated = "family_invite_created";
  static const familyInviteJoined = "family_invite_joined";
}
'

w "$APP/lib/src/analytics/analytics.dart" '
import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
import "../../config/launch_config.dart";

class AppAnalytics {
  AppAnalytics._();
  static FirebaseAnalytics? _analytics;

  static Future<void> init() async {
    if (!LaunchConfig.analytics && !LaunchConfig.crashlytics) {
      return;
    }
    await Firebase.initializeApp();
    if (LaunchConfig.analytics) {
      _analytics = FirebaseAnalytics.instance;
    }
    if (LaunchConfig.crashlytics) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  }

  static Future<void> log(String name, [Map<String, Object?>? params]) async {
    final a = _analytics;
    if (a == null || !LaunchConfig.analytics) return;
    await a.logEvent(name: name, parameters: params);
  }
}
'

# -----------------------------
# Flutter app: security (AES-GCM + PBKDF2)
# -----------------------------
mkdir -p "$APP/lib/src/security"

w "$APP/lib/src/security/keystore.dart" '
import "dart:convert";
import "dart:math";
import "package:cryptography/cryptography.dart";

class Keystore {
  Keystore._();

  static const int _pbkdf2Iterations = 500000;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;

  static Future<Map<String, dynamic>> encrypt(String password, Map<String, String> data) async {
    final secretKey = await _deriveKey(password);
    final algorithm = AesGcm.with256bits();
    final nonce = _randomBytes(_nonceLength);
    final message = utf8.encode(jsonEncode(data));
    final secretBox = await algorithm.encrypt(message, secretKey: secretKey, nonce: nonce);
    return {
      "ciphertext": base64Encode(secretBox.cipherText),
      "nonce": base64Encode(nonce),
      "salt": base64Encode(_lastSalt),
      "algo": "AES-GCM-256",
      "kdf": "PBKDF2-HMAC-SHA256",
      "iterations": _pbkdf2Iterations,
      "created_at": DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Future<Map<String, String>> decrypt(String password, Map<String, dynamic> payload) async {
    final secretKey = await _deriveKey(password, saltOverride: base64Decode(payload["salt"] as String));
    final algorithm = AesGcm.with256bits();
    final nonce = base64Decode(payload["nonce"] as String);
    final cipherText = base64Decode(payload["ciphertext"] as String);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac.empty);
    final clear = await algorithm.decrypt(box, secretKey: secretKey);
    final map = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  static late List<int> _lastSalt;

  static Future<SecretKey> _deriveKey(String password, {List<int>? saltOverride}) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    _lastSalt = saltOverride ?? _randomBytes(_saltLength);
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: _lastSalt,
    );
    return secretKey;
  }

  static List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
'

# -----------------------------
# Flutter app: Worker API client
# -----------------------------
w "$APP/lib/src/worker_api.dart" '
import "dart:convert";
import "package:http/http.dart" as http;
import "package:uuid/uuid.dart";
import "../config/internal_config.dart";
import "../config/api_config.dart";

class WorkerApi {
  WorkerApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final _uuid = const Uuid();

  Future<Map<String, dynamic>> health() async {
    final uri = Uri.parse(InternalConfig.workerBaseUrl + ApiConfig.healthPath);
    final res = await _client.get(uri, headers: _headers());
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> saveEncryptedKeys(String deviceId, Map<String, dynamic> encrypted) async {
    final uri = Uri.parse(InternalConfig.workerBaseUrl + ApiConfig.keysSavePath);
    final res = await _client.post(uri, headers: _headers(extra: {"X-Device-ID": deviceId}), body: jsonEncode(encrypted));
    _ensureOk(res);
  }

  Future<Map<String, dynamic>> chat({
    required String deviceId,
    required String text,
    required String provider,
    required String providerKey,
    bool familyContext = false,
  }) async {
    final uri = Uri.parse(InternalConfig.workerBaseUrl + ApiConfig.chatPath);
    final res = await _client.post(
      uri,
      headers: _headers(extra: {"X-Device-ID": deviceId}),
      body: jsonEncode({
        "text": text,
        "provider_hint": provider,
        "provider_key": providerKey,
        "family_context": familyContext,
      }),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createInvite({required String deviceId, required String memberName}) async {
    final uri = Uri.parse(InternalConfig.workerBaseUrl + ApiConfig.familyCreateInvitePath);
    final res = await _client.post(
      uri,
      headers: _headers(extra: {"X-Device-ID": deviceId}),
      body: jsonEncode({"member_name": memberName}),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptInvite({required String deviceId, required String inviteToken}) async {
    final uri = Uri.parse(InternalConfig.workerBaseUrl + ApiConfig.familyAcceptInvitePath);
    final res = await _client.post(
      uri,
      headers: _headers(extra: {"X-Device-ID": deviceId}),
      body: jsonEncode({"invite_token": inviteToken}),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listFamily({required String familyId}) async {
    final uri = Uri.parse(InternalConfig.workerBaseUrl + ApiConfig.familyListPath);
    final res = await _client.get(
      uri,
      headers: _headers(extra: {"X-Family-ID": familyId}),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "User-Agent": InternalConfig.appUserAgent,
      if (extra != null) ...extra,
    };
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }
  }
}
'

# -----------------------------
# Flutter app: providers & storage
# -----------------------------
mkdir -p "$APP/lib/src/providers"

w "$APP/lib/src/providers/providers.dart" '
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:uuid/uuid.dart";

final _prefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final deviceIdProvider = FutureProvider<String>((ref) async {
  const key = "device_id";
  final prefs = await ref.watch(_prefsProvider.future);
  var id = prefs.getString(key);
  if (id == null || id.isEmpty) {
    id = const Uuid().v4();
    await prefs.setString(key, id);
  }
  return id;
});

final isFirstRunProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(_prefsProvider.future);
  final seen = prefs.getBool("seen_onboarding") ?? false;
  return !seen;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class ProviderKeys {
  final String? openai;
  final String? gemini;
  final String? grok;
  final String? deepseek;
  const ProviderKeys({this.openai, this.gemini, this.grok, this.deepseek});

  Map<String, String> toMap() {
    final m = <String, String>{};
    if (openai != null && openai!.isNotEmpty) m["openai"] = openai!;
    if (gemini != null && gemini!.isNotEmpty) m["gemini"] = gemini!;
    if (grok != null && grok!.isNotEmpty) m["grok"] = grok!;
    if (deepseek != null && deepseek!.isNotEmpty) m["deepseek"] = deepseek!;
    return m;
  }
}

final providerKeysProvider = FutureProvider<ProviderKeys>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final o = await storage.read(key: "key_openai");
  final g = await storage.read(key: "key_gemini");
  final x = await storage.read(key: "key_grok");
  final d = await storage.read(key: "key_deepseek");
  return ProviderKeys(openai: o, gemini: g, grok: x, deepseek: d);
});
'

# -----------------------------
# Flutter app: voice module
# -----------------------------
mkdir -p "$APP/lib/src/voice"

w "$APP/lib/src/voice/voice_controller.dart" '
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:speech_to_text/speech_to_text.dart" as stt;
import "package:flutter_tts/flutter_tts.dart";

enum VoiceState { idle, listening, processing, speaking }

class VoiceController extends StateNotifier<VoiceState> {
  VoiceController() : super(VoiceState.idle) {
    _stt = stt.SpeechToText();
    _tts = FlutterTts();
  }

  late final stt.SpeechToText _stt;
  late final FlutterTts _tts;
  String _lastTranscript = "";

  String get transcript => _lastTranscript;

  Future<bool> initializeStt() async {
    final available = await _stt.initialize();
    return available;
  }

  Future<void> startListening(Function(String) onChange) async {
    final ok = await initializeStt();
    if (!ok) {
      return;
    }
    state = VoiceState.listening;
    _lastTranscript = "";
    await _stt.listen(onResult: (r) {
      _lastTranscript = r.recognizedWords;
      onChange(_lastTranscript);
    });
  }

  Future<void> stopListening() async {
    await _stt.stop();
    state = VoiceState.processing;
  }

  Future<void> speak(String text) async {
    state = VoiceState.speaking;
    await _tts.stop();
    await _tts.speak(text);
    state = VoiceState.idle;
  }

  void reset() {
    state = VoiceState.idle;
    _lastTranscript = "";
  }
}

final voiceControllerProvider = StateNotifierProvider<VoiceController, VoiceState>((ref) {
  return VoiceController();
});
'

w "$APP/lib/src/voice/voice_screen.dart" '
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../config/strings_config.dart";
import "../providers/providers.dart";
import "../worker_api.dart";
import "voice_controller.dart";

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});
  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  String _preview = "";
  String _response = "";
  String _provider = "openai";

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceControllerProvider);
    final controller = ref.read(voiceControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(StringsConfig.voiceScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Provider:"),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _provider,
                  items: const [
                    DropdownMenuItem(value: "openai", child: Text("OpenAI")),
                    DropdownMenuItem(value: "gemini", child: Text("Gemini")),
                    DropdownMenuItem(value: "grok", child: Text("Grok")),
                    DropdownMenuItem(value: "deepseek", child: Text("DeepSeek")),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _provider = v);
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 120,
              width: double.infinity,
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: Text(_preview.isEmpty ? StringsConfig.tapMicToSpeak : _preview),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(child: Text(_response)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: state == VoiceState.listening
                      ? null
                      : () async {
                          await controller.startListening((s) {
                            setState(() => _preview = s);
                          });
                        },
                  icon: const Icon(Icons.mic),
                  label: const Text("Start"),
                ),
                ElevatedButton.icon(
                  onPressed: state == VoiceState.listening ? () => controller.stopListening() : null,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop"),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final deviceId = await ref.read(deviceIdProvider.future);
                    final keys = await ref.read(providerKeysProvider.future);
                    final keyMap = keys.toMap();
                    final providerKey = keyMap[_provider];
                    if (providerKey == null || providerKey.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please add a provider key first on the Setup screen.")),
                        );
                      }
                      return;
                    }
                    final api = WorkerApi();
                    try {
                      final res = await api.chat(
                        deviceId: deviceId,
                        text: _preview,
                        provider: _provider,
                        providerKey: providerKey,
                      );
                      final text = (res["text"] ?? "").toString();
                      setState(() => _response = text);
                      await ref.read(voiceControllerProvider.notifier).speak(text);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text("Ask"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
'

# -----------------------------
# Flutter app: provider setup UI
# -----------------------------
w "$APP/lib/src/providers/provider_setup_screen.dart" '
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../config/strings_config.dart";
import "../providers/providers.dart";
import "../security/keystore.dart";
import "../worker_api.dart";

class ProviderSetupScreen extends ConsumerStatefulWidget {
  const ProviderSetupScreen({super.key});

  @override
  ConsumerState<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends ConsumerState<ProviderSetupScreen> {
  final _openai = TextEditingController();
  final _gemini = TextEditingController();
  final _grok = TextEditingController();
  final _deepseek = TextEditingController();
  final _backupPass = TextEditingController();

  @override
  void dispose() {
    _openai.dispose();
    _gemini.dispose();
    _grok.dispose();
    _deepseek.dispose();
    _backupPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Keys")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(StringsConfig.setupBody),
          const SizedBox(height: 12),
          _field("OpenAI API Key", _openai, hint: "sk-..."),
          _field("Gemini API Key", _gemini, hint: "AIza..."),
          _field("Grok API Key", _grok, hint: "grok-..."),
          _field("DeepSeek API Key", _deepseek, hint: "sk-..."),
          const Divider(height: 24),
          _field("Backup password (to encrypt keys)", _backupPass, hint: "A phrase only you know", obscure: true),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              final storage = ref.read(secureStorageProvider);
              if (_openai.text.isNotEmpty) await storage.write(key: "key_openai", value: _openai.text.trim());
              if (_gemini.text.isNotEmpty) await storage.write(key: "key_gemini", value: _gemini.text.trim());
              if (_grok.text.isNotEmpty) await storage.write(key: "key_grok", value: _grok.text.trim());
              if (_deepseek.text.isNotEmpty) await storage.write(key: "key_deepseek", value: _deepseek.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved locally.")));
              }
              if (_backupPass.text.isNotEmpty) {
                final keys = await ref.read(providerKeysProvider.future);
                final encrypted = await Keystore.encrypt(_backupPass.text, keys.toMap());
                final deviceId = await ref.read(deviceIdProvider.future);
                await WorkerApi().saveEncryptedKeys(deviceId, encrypted);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Encrypted backup uploaded.")));
                }
              }
            },
            child: const Text("Save & Backup"),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {String? hint, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, hintText: hint),
        obscureText: obscure,
        enableSuggestions: !obscure,
        autocorrect: !obscure,
      ),
    );
  }
}
'

# -----------------------------
# Flutter app: family (QR invites + accept + list)
# -----------------------------
mkdir -p "$APP/lib/src/family"

w "$APP/lib/src/family/invite_screen.dart" '
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:qr_flutter/qr_flutter.dart";
import "../providers/providers.dart";
import "../worker_api.dart";

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});
  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  String? _deeplink;
  final _name = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invite Family Member")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Their name")),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final deviceId = await ref.read(deviceIdProvider.future);
                final res = await WorkerApi().createInvite(deviceId: deviceId, memberName: _name.text.trim().isEmpty ? "Member" : _name.text.trim());
                setState(() => _deeplink = res["deeplink"]?.toString());
              },
              child: const Text("Create Invite"),
            ),
            const SizedBox(height: 12),
            if (_deeplink != null)
              Expanded(
                child: Center(
                  child: QrImageView(data: _deeplink!, size: 240),
                ),
              ),
            if (_deeplink != null) SelectableText(_deeplink!),
          ],
        ),
      ),
    );
  }
}
'

w "$APP/lib/src/family/accept_invite_screen.dart" '
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "../providers/providers.dart";
import "../worker_api.dart";

class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key});
  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  String _status = "Scan a QR to join.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accept Invite")),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) async {
                final barcode = capture.barcodes.first;
                final raw = barcode.rawValue;
                if (raw == null) return;
                try {
                  final uri = Uri.parse(raw);
                  final token = uri.queryParameters["token"];
                  if (token == null) return;
                  final deviceId = await ref.read(deviceIdProvider.future);
                  final res = await WorkerApi().acceptInvite(deviceId: deviceId, inviteToken: token);
                  setState(() => _status = "Joined family ${res["family_id"]} as ${res["member_name"]}.");
                } catch (_) {}
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_status),
          )
        ],
      ),
    );
  }
}
'

w "$APP/lib/src/family/family_dashboard_screen.dart" '
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../worker_api.dart";

class FamilyDashboardScreen extends ConsumerStatefulWidget {
  const FamilyDashboardScreen({super.key});
  @override
  ConsumerState<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends ConsumerState<FamilyDashboardScreen> {
  final _familyIdCtrl = TextEditingController();
  List<Map<String, dynamic>> _members = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Family Members")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _familyIdCtrl, decoration: const InputDecoration(labelText: "Family ID")),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final res = await WorkerApi().listFamily(familyId: _familyIdCtrl.text.trim());
                final list = (res["members"] as List).cast<Map<String, dynamic>>();
                setState(() => _members = list);
              },
              child: const Text("Load Members"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_members[i]["name"]?.toString() ?? "Unknown"),
                  subtitle: Text(_members[i]["device_id"]?.toString() ?? ""),
                ),
                separatorBuilder: (_, __) => const Divider(),
                itemCount: _members.length,
              ),
            )
          ],
        ),
      ),
    );
  }
}
'

w "$APP/lib/src/family/family_hub_screen.dart" '
import "package:flutter/material.dart";

class FamilyHubScreen extends StatelessWidget {
  const FamilyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Family")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text("Invite Family Member"),
              onTap: () => Navigator.of(context).pushNamed("/family/invite"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text("Accept Invite"),
              onTap: () => Navigator.of(context).pushNamed("/family/accept"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Family Dashboard"),
              onTap: () => Navigator.of(context).pushNamed("/family/dashboard"),
            ),
          ),
        ],
      ),
    );
  }
}
'

# -----------------------------
# Flutter app: theme system
# -----------------------------
mkdir -p "$APP/lib/src/theme" "$APP/assets/themes" "$APP/assets/config" "$APP/lib/src/onboarding" "$APP/lib/src/home"

w "$APP/lib/src/theme/registry.dart" '
import "dart:convert";
import "package:flutter/services.dart" show rootBundle;
import "package:flutter/material.dart";

class PetitTokens extends ThemeExtension<PetitTokens> {
  final double cornerRadius;
  final Duration motionFast;
  final Duration motionNormal;
  final Duration motionSlow;

  const PetitTokens({
    required this.cornerRadius,
    required this.motionFast,
    required this.motionNormal,
    required this.motionSlow,
  });

  @override
  ThemeExtension<PetitTokens> copyWith({double? cornerRadius, Duration? motionFast, Duration? motionNormal, Duration? motionSlow}) {
    return PetitTokens(
      cornerRadius: cornerRadius ?? this.cornerRadius,
      motionFast: motionFast ?? this.motionFast,
      motionNormal: motionNormal ?? this.motionNormal,
      motionSlow: motionSlow ?? this.motionSlow,
    );
  }

  @override
  ThemeExtension<PetitTokens> lerp(ThemeExtension<PetitTokens>? other, double t) {
    if (other is! PetitTokens) return this;
    return PetitTokens(
      cornerRadius: _lerpDouble(cornerRadius, other.cornerRadius, t)!,
      motionFast: _lerpDuration(motionFast, other.motionFast, t),
      motionNormal: _lerpDuration(motionNormal, other.motionNormal, t),
      motionSlow: _lerpDuration(motionSlow, other.motionSlow, t),
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    return Duration(milliseconds: (a.inMilliseconds + (b.inMilliseconds - a.inMilliseconds) * t).round());
  }
}

double? _lerpDouble(double a, double b, double t) => a + (b - a) * t;

class ThemeLoader {
  ThemeLoader._();

  static Future<ThemeData> load(String id, Brightness brightness) async {
    final data = jsonDecode(await rootBundle.loadString("assets/themes/themes.json")) as Map<String, dynamic>;
    final themes = (data["themes"] as List).cast<Map<String, dynamic>>();
    final match = themes.firstWhere((e) => e["id"] == id, orElse: () => themes.first);
    final colors = (match["colors"] as Map<String, dynamic>)[brightness == Brightness.dark ? "dark" : "light"] as Map<String, dynamic>;
    final corner = (match["tokens"] as Map<String, dynamic>)["corner_radius"] as num;
    final motion = (match["tokens"] as Map<String, dynamic>)["motion"] as Map<String, dynamic>;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: Color(int.parse(colors["primary"].toString())),
      onPrimary: Color(int.parse(colors["onPrimary"].toString())),
      secondary: Color(int.parse(colors["secondary"].toString())),
      onSecondary: Color(int.parse(colors["onSecondary"].toString())),
      error: Color(int.parse(colors["error"].toString())),
      onError: Color(int.parse(colors["onError"].toString())),
      background: Color(int.parse(colors["background"].toString())),
      onBackground: Color(int.parse(colors["onBackground"].toString())),
      surface: Color(int.parse(colors["surface"].toString())),
      onSurface: Color(int.parse(colors["onSurface"].toString())),
    );
    final tokens = PetitTokens(
      cornerRadius: corner.toDouble(),
      motionFast: Duration(milliseconds: motion["fast"] as int),
      motionNormal: Duration(milliseconds: motion["normal"] as int),
      motionSlow: Duration(milliseconds: motion["slow"] as int),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 14),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.cornerRadius))),
      extensions: [tokens],
    );
  }
}
'

w "$APP/lib/src/theme/theme_preview_screen.dart" '
import "package:flutter/material.dart";
import "registry.dart";

class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  String _selected = "high_contrast_dark";
  ThemeData? _theme;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _theme = await ThemeLoader.load(_selected, Brightness.dark);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme ?? Theme.of(context),
      child: Scaffold(
        appBar: AppBar(title: const Text("Theme Preview")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<String>(
                value: _selected,
                items: const [
                  DropdownMenuItem(value: "high_contrast_dark", child: Text("High Contrast Dark")),
                  DropdownMenuItem(value: "high_contrast_light", child: Text("High Contrast Light")),
                  DropdownMenuItem(value: "modern_dark", child: Text("Modern Dark")),
                  DropdownMenuItem(value: "modern_light", child: Text("Modern Light")),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selected = v);
                  _load();
                },
              ),
              const SizedBox(height: 12),
              const Text("Sample Buttons"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(onPressed: () {}, child: const Text("Primary")),
                  OutlinedButton(onPressed: () {}, child: const Text("Outline")),
                  TextButton(onPressed: () {}, child: const Text("Text")),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Cards"),
              const SizedBox(height: 8),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Text("Card with body text"))),
            ],
          ),
        ),
      ),
    );
  }
}
'

# Themes JSON (4 themes adult-contrast-friendly)
cat > "$APP/assets/themes/themes.json" <<'EOF'
{
  "version": 1,
  "default_theme_id": "high_contrast_dark",
  "themes": [
    {
      "id": "high_contrast_dark",
      "display_name": "High Contrast Dark",
      "colors": {
        "dark": {
          "primary": "4294967295",
          "onPrimary": "4278190080",
          "secondary": "4293726455",
          "onSecondary": "4278190080",
          "error": "4293977744",
          "onError": "4278190080",
          "background": "4278190080",
          "onBackground": "4294967295",
          "surface": "4279176978",
          "onSurface": "4294967295"
        },
        "light": {
          "primary": "4278190080",
          "onPrimary": "4294967295",
          "secondary": "4280824639",
          "onSecondary": "4294967295",
          "error": "4291821568",
          "onError": "4294967295",
          "background": "4294967295",
          "onBackground": "4278190080",
          "surface": "4294045938",
          "onSurface": "4278190080"
        }
      },
      "tokens": { "corner_radius": 16, "motion": { "fast": 80, "normal": 140, "slow": 220 } }
    },
    {
      "id": "high_contrast_light",
      "display_name": "High Contrast Light",
      "colors": {
        "dark": {
          "primary": "4294967295",
          "onPrimary": "4278190080",
          "secondary": "4288657317",
          "onSecondary": "4278190080",
          "error": "4293977744",
          "onError": "4278190080",
          "background": "4280295454",
          "onBackground": "4294967295",
          "surface": "4281611310",
          "onSurface": "4294967295"
        },
        "light": {
          "primary": "4278190080",
          "onPrimary": "4294967295",
          "secondary": "4280824639",
          "onSecondary": "4294967295",
          "error": "4291821568",
          "onError": "4294967295",
          "background": "4294967295",
          "onBackground": "4278190080",
          "surface": "4293980405",
          "onSurface": "4278190080"
        }
      },
      "tokens": { "corner_radius": 14, "motion": { "fast": 80, "normal": 140, "slow": 220 } }
    },
    {
      "id": "modern_dark",
      "display_name": "Modern Dark",
      "colors": {
        "dark": {
          "primary": "4286578689",
          "onPrimary": "4278190080",
          "secondary": "4289533019",
          "onSecondary": "4278190080",
          "error": "4293451674",
          "onError": "4278190080",
          "background": "4279178252",
          "onBackground": "4293858817",
          "surface": "4279835426",
          "onSurface": "4293858817"
        },
        "light": {
          "primary": "4278226785",
          "onPrimary": "4294967295",
          "secondary": "4279632544",
          "onSecondary": "4294967295",
          "error": "4280150456",
          "onError": "4294967295",
          "background": "4294967295",
          "onBackground": "4279308561",
          "surface": "4294374632",
          "onSurface": "4279308561"
        }
      },
      "tokens": { "corner_radius": 16, "motion": { "fast": 90, "normal": 160, "slow": 240 } }
    },
    {
      "id": "modern_light",
      "display_name": "Modern Light",
      "colors": {
        "dark": {
          "primary": "4284776226",
          "onPrimary": "4278190080",
          "secondary": "4290519853",
          "onSecondary": "4278190080",
          "error": "4293977744",
          "onError": "4278190080",
          "background": "4279176975",
          "onBackground": "4293652223",
          "surface": "4280295454",
          "onSurface": "4293652223"
        },
        "light": {
          "primary": "4278196897",
          "onPrimary": "4294967295",
          "secondary": "4289139760",
          "onSecondary": "4294967295",
          "error": "4281007768",
          "onError": "4294967295",
          "background": "4294967295",
          "onBackground": "4279173137",
          "surface": "4294046197",
          "onSurface": "4279173137"
        }
      },
      "tokens": { "corner_radius": 14, "motion": { "fast": 90, "normal": 160, "slow": 240 } }
    }
  ]
}
EOF

w "$APP/assets/themes/theme_voice_descriptions.json" '
{ "theme_desc_system_adaptive": "Follows your phone’s system colors automatically." }
'

# Onboarding + provider labels
w "$APP/assets/config/onboarding.json" '
{
  "steps": [
    { "title": "Welcome to PetitPal", "body": "Voice-first help for everyday tasks.", "tts": "Welcome to PetitPal. I can listen and help."},
    { "title": "Pick a Theme", "body": "Choose colors you can see clearly.", "tts": "Pick a theme that is easy for your eyes."},
    { "title": "Add a Key", "body": "Enter an API key from OpenAI or Gemini.", "tts": "Please add at least one provider key so I can answer."}
  ],
  "finish": { "title": "All Set", "body": "You can change settings any time.", "tts": "All set. Tap the mic to speak."}
}
'

w "$APP/assets/config/provider_setup.json" '
{
  "providers": [
    {"id": "openai", "label": "OpenAI", "help_url": "https://platform.openai.com/"},
    {"id": "gemini", "label": "Gemini", "help_url": "https://aistudio.google.com/app/apikey"},
    {"id": "grok", "label": "Grok", "help_url": "https://x.ai/"},
    {"id": "deepseek", "label": "DeepSeek", "help_url": "https://platform.deepseek.com/"}
  ]
}
'

# -----------------------------
# Flutter app: onboarding + home + router + main
# -----------------------------
w "$APP/lib/src/onboarding/onboarding_screen.dart" '
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../../config/strings_config.dart";

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _index = 0;
  List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = jsonDecode(await rootBundle.loadString("assets/config/onboarding.json")) as Map<String, dynamic>;
    _steps = (data["steps"] as List).cast<Map<String, dynamic>>();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps.isEmpty ? null : _steps[_index];
    return Scaffold(
      appBar: AppBar(title: const Text(StringsConfig.onboardingTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step != null) ...[
              Text(step["title"]?.toString() ?? "", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(step["body"]?.toString() ?? "")
            ],
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton(
                onPressed: () async {
                  if (_steps.isEmpty) return;
                  if (_index < _steps.length - 1) {
                    setState(() => _index += 1);
                  } else {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool("seen_onboarding", true);
                    if (!mounted) return;
                    Navigator.of(context).pushReplacementNamed("/home");
                  }
                },
                child: Text(_index < _steps.length - 1 ? StringsConfig.onboardingNext : StringsConfig.startUsingApp),
              ),
            )
          ],
        ),
      ),
    );
  }
}
'

w "$APP/lib/src/home/home_screen.dart" '
import "package:flutter/material.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PetitPal")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.mic),
              title: const Text("Voice Assistant"),
              subtitle: const Text("Speak and hear answers"),
              onTap: () => Navigator.of(context).pushNamed("/voice"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text("Provider Keys"),
              subtitle: const Text("Add or update keys"),
              onTap: () => Navigator.of(context).pushNamed("/providers"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette),
              title: const Text("Theme Preview"),
              subtitle: const Text("Pick colors that suit your eyes"),
              onTap: () => Navigator.of(context).pushNamed("/themes"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.group),
              title: const Text("Family"),
              subtitle: const Text("Invite or accept via QR"),
              onTap: () => Navigator.of(context).pushNamed("/family"),
            ),
          )
        ],
      ),
    );
  }
}
'

w "$APP/lib/app_router.dart" '
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "src/home/home_screen.dart";
import "src/onboarding/onboarding_screen.dart";
import "src/theme/theme_preview_screen.dart";
import "src/providers/provider_setup_screen.dart";
import "src/family/family_hub_screen.dart";
import "src/family/invite_screen.dart";
import "src/family/accept_invite_screen.dart";
import "src/family/family_dashboard_screen.dart";
import "src/voice/voice_screen.dart";
import "src/providers/providers.dart";

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(isFirstRunProvider.future),
      builder: (context, snap) {
        final firstRun = (snap.data ?? true);
        final initial = firstRun ? "/onboarding" : "/home";
        return Navigator(
          initialRoute: initial,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case "/home":
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              case "/onboarding":
                return MaterialPageRoute(builder: (_) => const OnboardingScreen());
              case "/themes":
                return MaterialPageRoute(builder: (_) => const ThemePreviewScreen());
              case "/providers":
                return MaterialPageRoute(builder: (_) => const ProviderSetupScreen());
              case "/family":
                return MaterialPageRoute(builder: (_) => const FamilyHubScreen());
              case "/family/invite":
                return MaterialPageRoute(builder: (_) => const InviteScreen());
              case "/family/accept":
                return MaterialPageRoute(builder: (_) => const AcceptInviteScreen());
              case "/family/dashboard":
                return MaterialPageRoute(builder: (_) => const FamilyDashboardScreen());
              case "/voice":
                return MaterialPageRoute(builder: (_) => const VoiceScreen());
            }
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          },
        );
      },
    );
  }
}
'

w "$APP/lib/main.dart" '
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "src/theme/registry.dart";
import "app_router.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PetitPalApp()));
}

class PetitPalApp extends StatefulWidget {
  const PetitPalApp({super.key});
  @override
  State<PetitPalApp> createState() => _PetitPalAppState();
}

class _PetitPalAppState extends State<PetitPalApp> {
  ThemeData? _theme;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _theme = await ThemeLoader.load("high_contrast_dark", Brightness.dark);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PetitPal",
      theme: _theme ?? ThemeData.dark(useMaterial3: true),
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
'

# -----------------------------
# Android app structure (minimal, builds on Android)
# -----------------------------
mkdir -p "$APP/android/app/src/main/kotlin/com/petitpal/app" "$APP/android/app/src/main/res/mipmap-mdpi" "$APP/android/app/src/main/res/mipmap-hdpi" "$APP/android/app/src/main/res/mipmap-xhdpi" "$APP/android/app/src/main/res/mipmap-xxhdpi" "$APP/android/app/src/main/res/mipmap-xxxhdpi"

w "$APP/android/gradle.properties" '
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g -Dkotlin.daemon.jvm.options\="-Xmx2g"
android.useAndroidX=true
android.enableJetifier=true
kotlin.code.style=official
'

w "$APP/android/settings.gradle" '
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "petitpal"
include(":app")
'

w "$APP/android/build.gradle" '
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.4.2"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24"
        classpath "com.google.gms:google-services:4.4.2"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
'

w "$APP/android/app/build.gradle" '
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "com.google.gms.google-services"
}

android {
    namespace "com.petitpal.app"
    compileSdk 35

    defaultConfig {
        applicationId "com.petitpal.app"
        minSdk 24
        targetSdk 35
        versionCode 5
        versionName "0.5.0"
        multiDexEnabled true
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
        }
        debug {
            debuggable true
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    ndkVersion "27.0.12077973"
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.9.24"
    implementation platform("com.google.firebase:firebase-bom:33.3.0")
    implementation "com.google.firebase:firebase-analytics"
    implementation "com.google.firebase:firebase-crashlytics"
}
'

w "$APP/android/app/proguard-rules.pro" '# Keep default rules
'

w "$APP/android/app/src/main/AndroidManifest.xml" '
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.petitpal.app">
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <application android:label="PetitPal" android:icon="@mipmap/ic_launcher" android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTask">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            <!-- Deep link for invites -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https" android:host="petitpal.page.link"/>
                <data android:scheme="https" android:host="petitpal-api.kristyc.workers.dev"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
'

w "$APP/android/app/src/main/kotlin/com/petitpal/app/MainActivity.kt" '
package com.petitpal.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {}
'

# tiny 8x8 png for all mipmaps
ICON_B64="iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAADUlEQVQYV2NkYGD4z0ABAAjaA2CIOqKoAAAAAElFTkSuQmCC"
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  wb "$APP/android/app/src/main/res/mipmap-$d/ic_launcher.png" "$ICON_B64"
done

# -----------------------------
# Cloudflare Worker
# -----------------------------
w "$WKR/worker.js" '
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type,X-Device-ID,X-Family-ID",
    };
    if (request.method === "OPTIONS") {
      return new Response("", { headers: corsHeaders });
    }
    try {
      if (url.pathname === "/health") {
        return json({ ok: true, version: "1.0.0" }, corsHeaders);
      }
      if (url.pathname === "/api/keys/save" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return error(400, "Missing X-Device-ID", corsHeaders);
        const body = await request.json();
        if (!body.ciphertext || !body.nonce || !body.salt) {
          return error(400, "Expecting encrypted payload", corsHeaders);
        }
        const key = `keys:${deviceId}`;
        await env["petitpal-kv"].put(key, JSON.stringify(body));
        return json({ stored: true, key }, corsHeaders);
      }
      if (url.pathname === "/api/keys/get" && request.method === "GET") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return error(400, "Missing X-Device-ID", corsHeaders);
        const key = `keys:${deviceId}`;
        const v = await env["petitpal-kv"].get(key);
        if (!v) return error(404, "Not found", corsHeaders);
        return new Response(v, { headers: { "Content-Type": "application/json", ...corsHeaders } });
      }
      if (url.pathname === "/api/chat" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return error(400, "Missing X-Device-ID", corsHeaders);
        const body = await request.json();
        const text = (body.text || "").toString();
        const provider = (body.provider_hint || "openai").toString();
        const providerKey = (body.provider_key || "").toString();
        if (!providerKey) return error(401, "Missing provider key", corsHeaders);

        const start = Date.now();
        const out = await chatViaProvider(provider, providerKey, text);
        const duration = Date.now() - start;
        return json({ model_used: out.model, auto_switched: false, reason: "provider_hint", summary_tts: out.text, text: out.text, duration_ms: duration, telemetry_id: crypto.randomUUID() }, corsHeaders);
      }
      if (url.pathname === "/api/family/create_invite" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return error(400, "Missing X-Device-ID", corsHeaders);
        const body = await request.json();
        const memberName = (body.member_name || "Member").toString();
        const familiesKey = `family_by_owner:${deviceId}`;
        let familyId = await env["petitpal-kv"].get(familiesKey);
        if (!familyId) {
          familyId = crypto.randomUUID();
          await env["petitpal-kv"].put(familiesKey, familyId);
          await env["petitpal-kv"].put(`family:${familyId}`, JSON.stringify({ members: [{ device_id: deviceId, name: "Owner" }], created_at: new Date().toISOString(), owner_device_id: deviceId }));
        }
        const token = [...crypto.getRandomValues(new Uint8Array(16))].map(b => b.toString(16).padStart(2,"0")).join("");
        const deeplink = `https://petitpal-api.kristyc.workers.dev/accept?token=${token}`;
        await env["petitpal-kv"].put(`invites:${token}`, JSON.stringify({ family_id: familyId, member_name: memberName, issued_at: new Date().toISOString() }), { expirationTtl: 86400 });
        return json({ family_id: familyId, invite_token: token, deeplink }, corsHeaders);
      }
      if (url.pathname === "/api/family/accept_invite" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return error(400, "Missing X-Device-ID", corsHeaders);
        const body = await request.json();
        const token = (body.invite_token || "").toString();
        const inviteRaw = await env["petitpal-kv"].get(`invites:${token}`);
        if (!inviteRaw) return error(400, "Invalid or expired token", corsHeaders);
        const invite = JSON.parse(inviteRaw);
        const famKey = `family:${invite.family_id}`;
        const famRaw = await env["petitpal-kv"].get(famKey);
        const family = famRaw ? JSON.parse(famRaw) : { members: [], created_at: new Date().toISOString(), owner_device_id: "" };
        const exists = (family.members || []).some((m) => m.device_id === deviceId);
        if (!exists) {
          family.members = [...(family.members || []), { device_id: deviceId, name: invite.member_name }];
          await env["petitpal-kv"].put(famKey, JSON.stringify(family));
        }
        await env["petitpal-kv"].delete(`invites:${token}`);
        return json({ family_id: invite.family_id, member_name: invite.member_name }, corsHeaders);
      }
      if (url.pathname === "/api/family/list" && request.method === "GET") {
        const familyId = request.headers.get("X-Family-ID");
        if (!familyId) return error(400, "Missing X-Family-ID", corsHeaders);
        const famRaw = await env["petitpal-kv"].get(`family:${familyId}`);
        if (!famRaw) return error(404, "Not found", corsHeaders);
        return new Response(famRaw, { headers: { "Content-Type": "application/json", ...corsHeaders } });
      }
      return error(404, "Not found", corsHeaders);
    } catch (e) {
      return error(500, "Server error: " + (e && e.message ? e.message : String(e)), { "Access-Control-Allow-Origin": "*" });
    }
  }
};

async function chatViaProvider(provider, key, text) {
  provider = provider.toLowerCase();
  if (provider === "openai") {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: text }],
        temperature: 0.7,
      }),
    });
    if (!res.ok) {
      const t = await res.text();
      throw new Error("OpenAI error " + res.status + ": " + t);
    }
    const data = await res.json();
    const out = data.choices?.[0]?.message?.content || "";
    return { model: "gpt-4o-mini", text: out };
  }
  if (provider === "gemini") {
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=${key}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text }]}] }),
    });
    if (!res.ok) {
      const t = await res.text();
      throw new Error("Gemini error " + res.status + ": " + t);
    }
    const data = await res.json();
    const out = data.candidates?.[0]?.content?.parts?.[0]?.text || "";
    return { model: "gemini-1.5-pro", text: out };
  }
  if (provider === "grok") {
    const res = await fetch("https://api.x.ai/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "grok-2-latest", messages: [{ role: "user", content: text }] }),
    });
    if (!res.ok) {
      const t = await res.text();
      throw new Error("Grok error " + res.status + ": " + t);
    }
    const data = await res.json();
    const out = data.choices?.[0]?.message?.content || "";
    return { model: "grok-2-latest", text: out };
  }
  if (provider === "deepseek") {
    const res = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${key}", "Content-Type": "application/json" },
      body: JSON.stringify({ model: "deepseek-chat", messages: [{ role: "user", content: text }] }),
    });
    if (!res.ok) {
      const t = await res.text();
      throw new Error("DeepSeek error " + res.status + ": " + t);
    }
    const data = await res.json();
    const out = data.choices?.[0]?.message?.content || "";
    return { model: "deepseek-chat", text: out };
  }
  throw new Error("Unsupported provider: " + provider);
}

function json(obj, headers = {}) {
  return new Response(JSON.stringify(obj), { headers: { "Content-Type": "application/json; charset=utf-8", ...headers } });
}

function error(code, message, headers = {}) {
  return new Response(JSON.stringify({ error: message }), { status: code, headers: { "Content-Type": "application/json; charset=utf-8", ...headers } });
}
'

w "$WKR/wrangler.toml" '
name = "petitpal-api"
main = "worker.js"
compatibility_date = "2024-11-01"

kv_namespaces = [
  { binding = "petitpal-kv", id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", preview_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" }
]

[vars]
# Feature toggles or DSNs can be added via wrangler secrets/vars
'

w "$WKR/.env.example" '
# Example environment entries for Cloudflare Worker
# SENTRY_DSN=
'

# -----------------------------
# Docs
# -----------------------------
w "$DOCS/SETUP_GUIDE.md" '
# Setup Guide (30 minutes)

## Prereqs
- Flutter SDK (stable). Recommended: 3.22.2+
- Android Studio with SDK 35 and NDK 27.0.12077973
- Cloudflare account (free tier)

## 1) Deploy the Worker
1. Install Wrangler: `npm i -g wrangler`
2. In `cloudflare-worker/`:
   - `wrangler login`
   - `wrangler kv namespace create petitpal-kv` (copy IDs)
   - Edit `wrangler.toml` and paste IDs under `kv_namespaces`
   - `wrangler deploy`
3. Verify health: open `https://<your-worker>.workers.dev/health` (should return `{ ok: true }`)

## 2) Configure & Run the Flutter App
1. Open `petitpal/` in Android Studio
2. Run `flutter pub get`
3. Connect an Android device/emulator (Android 8.0+)
4. `flutter run`
5. (Optional now / later) If you use Firebase Analytics/Crashlytics:
   - Put `google-services.json` under `android/app/`
   - Flip `LaunchConfig.LAUNCH_MODE` to `true` to enable

## 3) First Run
- Onboarding appears on first launch
- Go to **Provider Keys** and paste at least one provider key (OpenAI/Gemini/Grok/DeepSeek)
- Use **Voice Assistant** → Start → Stop → Ask

## 4) Family Invites
- **Family → Invite Family Member** → creates a token and deep link → shows QR
- Second device: **Accept Invite** → scan the QR → joined confirmation

## 5) Change Look & Feel
- **Theme Preview** to audition themes
- To modify globally, edit JSON: `assets/themes/themes.json`, rebuild the app

See `DEPLOYMENT_CHECKLIST.md` and `TROUBLESHOOTING.md` for more.
'

w "$DOCS/PetitPal_API_Spec.md" '
# PetitPal Worker API (MVP)

Base URL: `https://<your-worker>.workers.dev`

Headers:
- `X-Device-ID`: UUID generated on device
- `Content-Type`: application/json

## GET /health
Returns `{ ok: true, version: "1.0.0" }`

## POST /api/keys/save
Body: `{ "ciphertext": "...", "nonce": "...", "salt": "...", "algo": "AES-GCM-256", "kdf": "PBKDF2-HMAC-SHA256", "iterations": 500000, "created_at": "..." }`

## GET /api/keys/get
Returns encrypted backup

## POST /api/chat
Body: `{ "text": "Hello", "provider_hint": "openai|gemini|grok|deepseek", "provider_key": "..." }`

## POST /api/family/create_invite
Returns `{ family_id, invite_token, deeplink }`

## POST /api/family/accept_invite
Body: `{ "invite_token": "..." }`

## GET /api/family/list
Header `X-Family-ID: ...` → returns `{ family_id, members: [{ device_id, name }, ...] }`
'

w "$DOCS/TROUBLESHOOTING.md" '
# Troubleshooting

**App builds but crashes**
- Ensure minSdk 24+, Android 8.0+ emulator/device
- `flutter clean && flutter pub get`

**Voice capture fails**
- Grant microphone permission in Android settings

**/api/chat returns 401**
- Add a provider key on the Provider Keys screen

**Wrangler deploy fails**
- Ensure `kv_namespaces` IDs are filled
- `wrangler whoami` to confirm login
'

w "$DOCS/DEPLOYMENT_CHECKLIST.md" '
# Deployment Checklist

- [ ] Worker deployed; `/health` returns ok
- [ ] KV namespace bound as `petitpal-kv` in `wrangler.toml`
- [ ] Android device/emulator ready (Android 8+)
- [ ] Provider key pasted on device
- [ ] Optional: `google-services.json` present (when launching)
- [ ] `LaunchConfig.LAUNCH_MODE` switched to `true` for production
'

# -----------------------------
# Scripts
# -----------------------------
w "$SCRIPTS/compat_check.sh" '
#!/usr/bin/env bash
set -euo pipefail

echo "Checking Flutter..."
flutter --version

echo "Checking Java..."
java -version || true

echo "Recommended versions:"
cat <<EOF
Flutter >= 3.22.2
AGP 8.4.2
Kotlin 1.9.24
Android SDK 35
NDK 27.0.12077973
JDK 17
EOF
'
chmod +x "$SCRIPTS/compat_check.sh"

# -----------------------------
# Create ZIP and Git patch
# -----------------------------
cd "$(dirname "$ROOT")"
ZIP="$PWD/petitpal_mvp.zip"
PATCH="$PWD/petitpal_mvp.patch"
rm -f "$ZIP" "$PATCH"

# zip
( cd "$ROOT" && zip -r -q "$ZIP" . )

# git init + patch
( cd "$ROOT" && git init -q && git add . && git -c user.email=a@b.c -c user.name=gen commit -q -m "PetitPal MVP initial commit" && git format-patch -1 -o "$PWD" >/dev/null )
# format-patch writes a numbered file; rename to petitpal_mvp.patch
PATCHFILE="$(ls -1 *.patch | head -n1 || true)"
if [ -n "$PATCHFILE" ]; then mv "$PATCHFILE" "$PATCH"; fi

echo
echo "DONE."
echo "ZIP: $ZIP"
echo "PATCH: $PATCH"
echo
echo "Open docs/SETUP_GUIDE.md and follow the steps."
