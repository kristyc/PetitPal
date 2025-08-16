# PetitPal MVP (B1)

This overlay adds:
- Flutter app code under `petitpal/lib` (onboarding, themes, voice, worker API client)
- Cloudflare Worker under `cloudflare-worker/`
- Central config at `petitpal/lib/config/internal_config.dart`

## Quick Start

1) **Copy files** into your repo, keeping the same folder names.
2) In a terminal from the `petitpal/` folder:
   ```bash
   flutter pub get
   flutter run -d emulator-5554
   ```
3) Test the Worker locally:
   ```bash
   cd cloudflare-worker
   wrangler dev
   ```

### Android package
The app uses package `com.petitpal.app`. No Firebase is required for B1.

### Where to change things
- Toggles, DSNs, Worker URL: `lib/config/internal_config.dart`
- Themes: `lib/src/theme/themes.dart`
- Onboarding: `lib/src/onboarding/onboarding_flow.dart`
- Voice UI: `lib/src/voice/voice_screen.dart`
- Worker routes: `cloudflare-worker/worker.js`

### Firebase (optional, later)
We intentionally skipped Gradle plugins so you can add `google-services.json` later without breaking the B1 build.
