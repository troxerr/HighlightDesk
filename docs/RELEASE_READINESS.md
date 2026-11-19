# Chatclip 3.0 readiness report

Date: 2026-11-15 · Version: 3.0.0 · Status: **blocked on external launch credentials**

## Verified in this workspace

| Area | Evidence |
|---|---|
| Node tests | 166/166 pass (`npm test`), re-run 2026-11-17 |
| Persistence hardening | Corrupt state files are quarantined, failed writes keep memory authoritative and self-heal, no truncated drafts; `tools/soak.js` passes |
| Crash reports | `lib/crashlog.js` writes bounded reports on uncaught errors; included in diagnostics zip (app rebuild not yet verified) |
| Arm64 media | 8/8 exporter/reframe tests pass with `mac/runtime/arm64/bin` |
| x86_64 media | 8/8 exporter/reframe tests pass with `mac/runtime/x86_64/bin` |
| Arm64 app | Builds, embeds Sparkle + runtime, deep code-sign verifies |
| x86_64 app | Builds, embeds Sparkle + runtime, deep code-sign verifies, launches under Rosetta |
| Self-contained arm64 | Engine produced a 1080×1920 clip with `PATH=/usr/bin:/bin` and no system FFmpeg/Streamlink |
| DMGs | Both `hdiutil verify` VALID, mount, and apps launch with `PATH=/usr/bin:/bin` |
| Licensing | Trial/activation/validation/deactivation helper tested; development app unlocked |
| OAuth | Dropbox PKCE + Google bridge helpers tested; one-click storage UI builds |
| Updates | Sparkle 2.10.1 embedded; appcast signing helper present; no live feed |
| Diagnostics | Redacted config/queue/history/log/runtime/signing export implemented |
| Notifications | Clip, upload, queued-retry, and failure notifications implemented |
| Launch at login | `SMAppService` toggle implemented |
| Website | Landing/privacy/terms/EULA templates; local links validate; Pages workflow added |
| Release gate | `./mac/release.sh --check` reports 12 external blockers |

Artifacts:

- `mac/build/Chatclip.app` (arm64, ad-hoc)
- `mac/build/Chatclip x86_64.app` (x86_64, ad-hoc)
- `mac/build/Chatclip-3.0.0-arm64-unsigned.dmg`
- `mac/build/Chatclip-3.0.0-x86_64-unsigned.dmg`
- `mac/build/Chatclip-3.0.0-*.zip`

## External blockers

| Owner | Required | Why it blocks |
|---|---|---|
| Apple | Developer ID Application cert, notarytool credentials | Current apps are ad-hoc; `spctl` rejects them |
| Dropbox | Vendor app key, scopes, redirect, production approval | Current OAuth is code-only without a vendor client |
| Google | Desktop OAuth client, published/verified consent screen | Current OAuth is code-only without a vendor client |
| Lemon Squeezy | Product, checkout, license keys, refund/trial policy | Activation cannot be tested end-to-end |
| Hosting | Domain + HTTPS for site, DMGs, appcast | No public download/update feed |
| Sparkle | EdDSA key pair, hosted appcast, update test | Framework integrated, feed not configured |
| Legal | Reviewed EULA/privacy/terms/refund/consent | Templates are not legal advice |
| Pilot | 15 macOS streamers + consent | No demand/refund/support evidence |

## Commands to continue

```sh
# rebuild runtimes if needed
./tools/build-runtime.sh

# build one architecture
NODE_BIN=/path/to/node ./mac/build.sh
ARCH=x86_64 NODE_BIN=/path/to/node-x64 ./mac/build.sh

# unsigned QA package
FORMAT=zip ARCH=arm64 ./tools/package-unsigned.sh

# release gate
./mac/release.sh --check

# signed/notarized release (once credentials exist)
DEVELOPER_ID_APPLICATION="Developer ID Application: ..." \
NOTARY_PROFILE="highlightdesk-notary" \
SU_FEED_URL="https://.../appcast.xml" \
SU_PUBLIC_ED_KEY="..." \
./mac/build.sh
./mac/release.sh
```

## Honest conclusion

The app is not yet sellable. The remaining work is account access, legal review, a hosted update feed, and pilot evidence — not missing storage, licensing, packaging, or runtime code. Do not publish an unsigned/ad-hoc DMG or ship a test Sparkle key.
