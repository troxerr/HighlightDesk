# Commercial readiness checklist

Status is intentionally honest: unchecked items are launch blockers.

## Product

- [x] Local-only storage with vertical output and sidecar
- [x] Dropbox upload with size confirmation and local cleanup
- [x] Google Drive upload with size confirmation and local cleanup
- [x] Provider-aware selection and configuration
- [x] Persistent failed-upload queue and retry
- [x] Clip history
- [x] Hardware H.264 default (no GPL libx264 in the commercial bundle)
- [x] One-click Dropbox OAuth UI (PKCE) with Keychain
- [x] One-click Google Drive OAuth UI with Keychain
- [x] First-run Getting Started guide
- [ ] Multi-step onboarding wizard
- [x] Storage settings UI (no JSON required for storage)
- [x] Legacy refresh-token migration to Keychain
- [x] History/queue UI with open-local/open-remote
- [x] In-app diagnostics export with redacted config
- [x] Launch-at-login toggle (`SMAppService`)
- [x] Clip, upload, queued-retry, and upload-failure notifications
- [x] License/trial UI, activation, deactivation, offline grace
- [ ] Lemon Squeezy product/checkout configured
- [x] Sparkle 2 integration + appcast helper
- [ ] Sparkle feed hosted and update path tested
- [x] Keychain migration from the current config file
- [ ] Vendor OAuth app credentials injected for release

## Distribution

- [x] Ad-hoc local app build
- [x] Release signing/notarization/DMG script
- [ ] Apple Developer ID certificate installed
- [ ] Notarized DMG accepted by Gatekeeper
- [x] Bundled LGPL FFmpeg (VideoToolbox)
- [x] Bundled self-contained Streamlink
- [x] arm64 runtime bundled
- [x] x86_64 runtime + app built locally (unsigned)
- [ ] Signed/notarized x86_64 DMG
- [ ] Clean-Mac install test
- [x] Crash reports written to `crashes/` in the state dir and included in Export Diagnostics (local only; no automatic upload; Objective-C change not yet rebuilt/verified in the app)
- [ ] Appcast and update test

## Commerce and legal

- [ ] Lemon Squeezy product and checkout account
- [x] Lemon Squeezy license API helper
- [ ] EULA, privacy, terms, refund policy
- [ ] Copyright/streamer-consent language
- [~] Third-party licenses and LGPL source offer: written offer added to `docs/THIRD_PARTY_NOTICES.md`; needs a real support email and the LGPL text shipped in the bundle
- [ ] Domain, website, checkout, support email
- [ ] Trademark/brand review
- [ ] 15-user pilot and paid-pilot gate

## Test evidence

- [x] 166 Node tests (includes corrupt-state, disk-full recovery, crash-report and restart/backoff tests)
- [x] Persistence soak harness (`node tools/soak.js`): 20,000 simulated clips with injected write failures, no lost entries
- [x] Live local pipeline test
- [x] Google Drive mock pipeline test
- [x] Persistent queue retry test
- [x] OAuth bridge unit tests + loopback callback tests
- [x] License helper tests
- [x] Self-contained arm64 engine test with no system FFmpeg/Streamlink
- [x] x86_64 app launched under Rosetta + x86 media tests pass
- [x] Packaged arm/x86 zips launch with minimal PATH
- [x] Unsigned arm/x86 DMGs mount and launch with minimal PATH
- [ ] Signed/notarized DMG mounted and installed on clean Mac
- [x] History and Getting Started UI verified
- [x] Real Dropbox/Live Twitch manual pipeline (historical)
- [ ] 24-hour soak
- [~] Disk-full / interrupted-upload / sleep-wake backoff covered for the queue and history store; real network-loss and whole-recorder sleep-wake still need a manual pass
- [ ] License/update/notarization tests
- [ ] Clean macOS 13/14/15 matrix
