# PetitPal — MVP Ready-to-Merge Bundle

This bundle adds the **missing backend & scaffolding**, deep links, provider setup screens,
family sharing endpoints, analytics toggles, and complete docs.

## Quick Start

1. **Cloudflare Worker**
   - `cd cloudflare-worker`
   - Set KV binding `petitpal-kv` in dashboard or wrangler.
   - `wrangler deploy`

2. **Flutter app**
   - Merge `app/lib/**` into your project.
   - Add deep-link intent-filter (Android) for `petitpal://invite/*` (see SETUP_GUIDE.md).
   - Run the app and complete onboarding.

3. **Test**
   - Invite: create invite, scan QR on second device/emulator, auto-join.
   - Ask questions that trigger **auto-switch** (news/how-to/quick/chat).

See `SETUP_GUIDE.md` for screenshots and step-by-step details.
