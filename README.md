# PetitPal (Android-first MVP)

Updated 2025-08-17

## What’s included
- High-contrast dark Flutter UI, big mic button.
- Settings to store OpenAI API key **securely** on device.
- Cloudflare Worker proxy (voice transcription + answer).
- **Android** manifest with permissions for Internet and Microphone.

## Quick start (Android)
```bash
flutter create . --platforms=android   # if platform files are missing/need refresh
flutter pub get
flutter run -d android
```
The correct manifest is already at `android/app/src/main/AndroidManifest.xml`.

## Config
All tweakables live in `lib/config.dart` and are hardcoded for prod:
- WORKER BASE URL: https://petitpal-api.kristyc.workers.dev
- WORKER FILENAME: https://petitpal-api.kristyc.workers.dev/worker.js
- KV namespace: petitpal-kv
- KV binding variable: petitpal-kv
- Default model: gpt-4o-mini

(Cloudflare KV is referenced for future use; this MVP **does not** persist user data.)

## Permissions
- `INTERNET` for API calls
- `RECORD_AUDIO` for recording questions

## Notes
- The app records to M4A (AAC LC), posts bytes to `/api/voice_chat`, Worker transcribes with `whisper-1`, then replies via Chat Completions. App speaks the answer with TTS.
