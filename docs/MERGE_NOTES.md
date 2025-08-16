# Merge Notes

- This bundle is structured to be merged into your existing repo:
  - `cloudflare-worker/**` → your Worker project.
  - `app/lib/**` → your Flutter app (new folders fit under `lib/src/`).
  - Docs at repo root.
- Make sure your AndroidManifest has the deep link intent-filter (see SETUP_GUIDE.md).
- Replace placeholder AES-GCM with a production crypto implementation.
- Finish out the remaining 6 theme descriptors in `registry.dart`.
