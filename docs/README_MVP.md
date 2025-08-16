# PetitPal MVP v1.0 (Full package)

## What’s included
- Flutter app with Riverpod, onboarding (theme + provider setup), voice PTT, settings (theme + default provider), family hub (QR invite display & join stub), offline banner, and error handling.
- Cloudflare Worker proxy that routes to OpenAI, Gemini, xAI, and DeepSeek. No keys are stored by default; app sends the key per request.
- Central config: `lib/config/internal_config.dart`

## Run
1. Flutter
   ```bash
   cd petitpal
   flutter pub get
   flutter run
   ```

2. Worker
   ```bash
   cd ../cloudflare-worker
   npm i -g wrangler
   wrangler login
   wrangler kv namespace create petitpal-kv   # once
   # paste the ID into wrangler.toml
   wrangler deploy
   ```

## Where to change things
- Toggles/DSNs/Worker URL: `lib/config/internal_config.dart`
- Themes: `lib/src/theme/themes.dart`
- Provider setup UI: `lib/src/onboarding/provider_setup_step.dart`
- Worker calls: `cloudflare-worker/worker.js`

## Notes
- Camera/QR scanning is postponed to a later build to avoid AGP issues; invite QR display + code paste are in place.
- Firebase (Analytics/Crashlytics) is off by default; enable later with Gradle plugin + JSON and toggles in `InternalConfig`.
