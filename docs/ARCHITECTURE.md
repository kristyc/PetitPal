# Architecture

- **Flutter** feature folders under `lib/src` (voice, theme, onboarding, providers, family, analytics, security).
- **Cloudflare Worker** proxies all providers and handles family + encrypted backups (KV).
- **Anonymous** device UUID, no PII, encrypted-at-rest backups.
- **Launch toggles** centralized in `lib/config/internal_config.dart`.
- **Events taxonomy** in `lib/src/analytics/events.dart`.
