# Windows plan

Status: proposal. Date: 2026-11-18. Nothing in this document is implemented yet.

Goal: ship a monetizable Windows version of Highlight Desk, reusing the existing Node engine and replacing the macOS-only layers.

## 1. Current state

The repo is a Mac product with a portable engine inside it.

| Layer | Size | Windows status |
|---|---|---|
| Engine (`background.cjs`, `lib/*`, `vod.cjs`, `dist/{reactions,irc,config}.js`) | about 4.5k lines of Node | Mostly portable |
| Native UI (`mac/main.m`, `mac/ui/*`) | about 5k lines of Cocoa | Must be rewritten |
| Packaging (`mac/*.sh`, Sparkle, notarization) | | Replaced entirely |
| Licensing (`tools/license.js`, Lemon Squeezy) | | Portable as is |
| Site, legal templates, pilot plan | | Reusable with edits |

The product records the stream through Streamlink and FFmpeg, detects chat spikes, and cuts a 30-second clip. It reframes the clip to 9:16 and saves it locally or to Dropbox or Google Drive. It also has a Twitch past-broadcast scanner, a monitor that tunes detection from user ratings, and a 7-day trial with a license key.

`docs/RELEASE_READINESS.md` says the Mac app is not yet sellable because of external accounts (Apple certificate, OAuth vendor apps, Lemon Squeezy, hosting, legal review). There is no pilot evidence of demand yet.

### Mac-specific code to change

| Area | Location | Issue |
|---|---|---|
| Encoder | `lib/encoder.js` | Only `h264_videotoolbox` and `libx264` are supported |
| Credentials | `lib/appconfig.js` (`keychainToken`) | Returns empty on non-`darwin` |
| Manual save | `background.cjs` (`SIGUSR2`, `SIGUSR1`) | Windows has no equivalent signals |
| Paths | `background.cjs`, `vod.cjs` | `~/Movies/Highlight Desk`; state in `~/Library/Application Support` |
| Fonts | `lib/overlays.js` | Hardcoded `/System/Library/Fonts/...`, plus an `/opt/homebrew` FFmpeg path |
| Browser open | `tools/oauth-bridge.js` | `cmd /c start` mangles URLs containing `&` |
| Kick | `lib/kick-relay.js`, `docs/KICK.md` | Needs a webhook, a tunnel and Keychain; unverified live |

## 2. Shell decision: Electron around the existing Node engine

| Option | Verdict |
|---|---|
| Electron + Node engine (recommended) | Reuses about 90% of the engine unchanged. Node is already bundled. `electron-builder` covers the installer and `electron-updater`. `safeStorage` covers Credential Manager/DPAPI. The login item and toast notifications are built in. Installer is about 150–200 MB. |
| Tauri | Smaller shell, but a Node sidecar is still needed, so most of the size benefit disappears. It also adds Rust to the stack. |
| WinUI / WPF | Closest to the Mac app's native feel, but needs a full UI rewrite plus a sidecar. Slowest route to revenue. |
| Browser dashboard (`dist/`) | Keep as a free funnel and demo. |

The existing `HIGHLIGHT_DESK_EVENTS=1` JSONL protocol is already the boundary between engine and UI. The Electron main process runs the engine as a child process, consumes the same events the Cocoa UI uses, and sends commands over stdin. The stdin channel replaces `SIGUSR2`.

## 3. Technical work

1. **Platform layer.** Add `lib/platform.js` for paths (`%APPDATA%`, `Videos`), fonts (`C:\Windows\Fonts\arialbd.ttf`) and binary lookup. Open URLs with Electron's `shell.openExternal`.
2. **Encoders.** Probe at startup and use the first encoder that passes a 1-second test encode: `h264_nvenc`, `h264_qsv`, `h264_amf`, then `h264_mf` (software Media Foundation, works everywhere). All are compatible with an LGPL FFmpeg build. Do not bundle libx264 (GPL). Base the bundled FFmpeg on BtbN `win64-lgpl` builds or build it from source. Record the exact build flags for the LGPL source offer.
3. **Streamlink.** Use the official portable Windows build (BSD 2-Clause). Update `docs/THIRD_PARTY_NOTICES.md`.
4. **Secrets.** Store OAuth refresh tokens and the license key with `safeStorage`. Today the license key sits in a 0600 config file, which does not translate to Windows.
5. **GPU contention.** Streamers game and stream on the same PC. Run FFmpeg at below-normal priority, prefer NVENC, and add a throttle or pause-exports-while-gaming option. This is the main thing that can make the product feel bad on Windows.
6. **UI.** Port Capture, Clips, Storage, Settings and Monitor. `docs/DESIGN.md` and `docs/screenshots` are the spec. `dist/desk.js` already contains some browser-side logic that can be reused.
7. **CI.** Add `windows-latest` to `.github/workflows/build.yml`. The Node tests can run on Linux, but Windows binaries, the installer and signing must be verified on a Windows machine or VM.

## 4. Capture source: add OBS

On Windows the streamer is almost always running OBS on the same machine. Add an OBS source (OBS WebSocket replay buffer, or watching the local recording) alongside Streamlink.

- Avoids Twitch ads in clips, which the README lists as a limitation.
- Gives source-quality video with no extra download bandwidth.
- Works for Kick, YouTube and any other destination OBS streams to.
- Reduces legal and fragility risk, because the user clips their own stream.

Position the product as "clips your own stream". Streamlink watching becomes a secondary mode.

## 5. Monetization

### Competition

Twitch's clip editor, Streamlabs Highlighter, StreamLadder, Eklipse, Medal and Opus Clip all overlap and are heavily free or freemium. Do not compete on AI editing. The defensible pitch is:

- local-first
- hands-off (runs unattended, delivers to the user's own Drive or Dropbox)
- driven by chat signal
- no per-minute credits
- video is never uploaded to a vendor

### Pricing (hypotheses to test in the pilot)

The current pilot tests $39 one-time. Ongoing costs (Streamlink and Twitch breakage fixes, FFmpeg updates, support) are not covered by a one-time price.

| Tier | Proposal |
|---|---|
| Free | Browser dashboard, plus a capped Windows app (for example 3 clips/day, local only) |
| Pro | $6/month or $49/year: unlimited clips, cloud storage, VOD scan, monitor tuning |
| Lifetime | About $99 in a limited launch window |

Keep Lemon Squeezy (merchant of record, handles VAT) or compare Paddle or Polar. `tools/license.js` already works with Lemon Squeezy.

### Distribution

- Direct download first, from a domain you control. NSIS installer, with `electron-updater` feed hosted on R2 or GitHub Releases.
- Code signing: Azure Trusted Signing (about $10/month; confirm region and entity eligibility) or an OV/EV certificate. Unsigned builds trigger SmartScreen warnings and will hurt conversion.
- Microsoft Store (MSIX) as a later second channel.

## 6. Risks to resolve before charging

1. **Twitch terms.** Recording through Streamlink and scanning VODs through `gql.twitch.tv` with the public client ID are both unofficial. Treat them as fragile and legally gray. Lead with the OBS source and "your own channel", and have counsel review the EULA, privacy policy and consent language.
2. **Kick.** Defer on Windows v1. It needs a hosted relay with a server-side secret, and it is unverified against a live broadcast.
3. **OAuth vendor apps.** Dropbox needs production approval beyond its development limits. Google's `drive.file` is a light scope, so verification should be manageable.
4. **Demand.** The pilot gate in `docs/PILOT.md` (15 streamers; first clip within 30 minutes; trial-to-paid; at least 40% "very disappointed" in the Sean Ellis survey) has not been run. Keep it as the launch gate and use Windows streamers as the cohort.
5. **Performance on gaming PCs.** See section 3, item 5. Test with a real game plus OBS running.

## 7. Roadmap

Estimates assume one developer.

| Phase | Scope | Exit criteria |
|---|---|---|
| 0 (about 1 week) | Platform layer, encoder probe, stdin command channel, Windows CI, `npm test` green on Windows | Engine produces a 1080×1920 clip on Windows with bundled binaries |
| 1 (about 3–4 weeks) | Electron shell: Capture, Clips, Storage, Settings; trial and license; `safeStorage`; toasts; login item | Internal alpha on 2–3 PCs |
| 2 (about 2–3 weeks) | OBS source; signed NSIS installer; auto-update; site and legal updates; crash and diagnostics export | Signed installer installs on a clean Windows 10 and 11 |
| 3 (about 2 weeks) | Paid pilot with 15 Windows streamers; price testing | Pilot gate met |
| 4 | Public launch; Store listing; VOD scan and monitor polish; Kick if there is demand | |

Phases 0–2 total roughly 6–8 weeks.

## 8. Account and setup lead times

Start these early because they depend on third parties:

- Code signing (Azure Trusted Signing or certificate vendor)
- Domain, HTTPS hosting, support email
- Lemon Squeezy (or alternative) product and checkout
- Dropbox production approval and Google OAuth consent screen
- Legal review

## 9. Decisions needed

1. Confirm Electron as the shell.
2. Confirm OBS-first positioning.
3. Choose pricing model to test (one-time, subscription, or both).
4. Decide whether Kick is out of scope for Windows v1.
