# PetitPal — Android Voice MVP

Updated 2025-08-17

## What’s included
- **Android-first** Flutter app with high-contrast dark theme.
- **Big mic button** → record M4A → send to Worker → TTS speak reply.
- **Settings**: add/edit OpenAI key, request/reset microphone permission, open Diagnostics.
- **Diagnostics**: one-tap end-to-end test (text ping, 2s record, amplitude logs, playback, server roundtrip).
- **Config** in `lib/config.dart` (hardcoded):
  - BASE: https://petitpal-api.kristyc.workers.dev
  - FILENAME: https://petitpal-api.kristyc.workers.dev/worker.js
  - KV namespace: petitpal-kv (binding: petitpal-kv)

## Android config
- `minSdk = 23`, `ndkVersion = 27.0.12077973`
- Manifest includes `INTERNET` and `RECORD_AUDIO`.

## Quick start
```bash
flutter create . --platforms=android   # if platform scaffolding is missing
flutter pub get
flutter run -d android
```
Paste your **OpenAI key** in **Settings**.

## Notes
- Audio recorded via `record` as **AAC (m4a)** 44.1 kHz mono at 128 kbps.
- No on-device STT: Worker uses OpenAI transcription + chat.
- Keys stored on-device with `flutter_secure_storage`.
