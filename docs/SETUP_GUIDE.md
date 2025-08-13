# Setup Guide (with screenshots)

## Prereqs
- Flutter (stable), Android SDK, a physical or virtual device.
- Cloudflare account (Workers + KV), Firebase project (optional for MVP), Sentry DSN (optional).

## Cloudflare Worker
1. Open Cloudflare dashboard → **Workers & Pages** → Create a Worker named `petitpal-api`.
2. Add a **KV Namespace** called `petitpal-kv` and bind it to the Worker.
3. Paste `cloudflare-worker/worker.js` into the editor, set compatibility date, and **Deploy**.
4. (Optional) Add Sentry DSN as a secret.

## Deep Links (Android)
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="petitpal" android:host="invite"/>
</intent-filter>
```

## Firebase (optional now)
- Add `google-services.json` to `android/app/`.
- Flip toggles in `lib/config/internal_config.dart` when launching.

## Keys (temporary live call path)
During MVP, pass provider keys only for the active /api/chat call:
```dart
final res = await api.chat(
  text: "What's the latest on ...",
  liveKeys: {
    "openai": "<sk-...>",
    "gemini": "<AIza...>",
    "grok": "<xai_...>",
    "deepseek": "<ds_...>"
  },
);
```
Keys are **not persisted** server-side. Encrypted backups are stored as blobs in KV separately.
