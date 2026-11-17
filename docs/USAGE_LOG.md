# Highlight Desk Usage Log

Generated **2026-11-16T02:06:24.632Z** by `tools/usage-audit.js`. Local-only; no data was uploaded.

## Snapshot

| Item | Value |
|---|---|
| App version | 3.0.0 (build unknown) |
| State directory | `~/Library/Application Support/Highlight Desk` |
| Clips directory | `~/Movies/Highlight Desk` |
| History rows | 22 |
| Sidecars | 22 |
| Rendered 9:16 files present | 0 |
| Raw/intermediate files present | 4 |
| Total local media | 70.7 MB |
| Queue jobs | 0 |
| Usage events | 0 |
| Chat samples | 0 |
| Capture sessions in log | 0 |
| Storage mode | dropbox |
| Dropbox configured | yes |
| Google Drive configured | no |

## Clip and detection summary

- Providers: dropbox 22
- History statuses: uploaded 22
- Auto/chat-spike clips: **22**
- Clip participants: median **77**, min **45**, max **381**
- Clip reactions: median **55**, min **23**, max **235**
- Clip scores: median **3.10**, min **1.72**, max **14.65**
- Messages at trigger: median **82**, min **50**, max **629**
- Reactions per message: median **0.64**
- Clip sizes: median **20.6 MB**, min **6.1 MB**, max **20.7 MB**
- Close auto pairs (<5 min): **10**
- Page views: none
- Triggered chat samples: **0** of 0

### Recent clips

- 2026-11-16T01:37:33.408Z · **Chat spike · 46 viewers · uuh ×12** · dropbox · uploaded · 46 participants · 23 reactions · score 4
- 2026-11-16T01:12:58.073Z · **Chat spike · 89 viewers · OOOO ×26** · dropbox · uploaded · 89 participants · 58 reactions · score 2.62
- 2026-11-16T01:08:23.019Z · **Chat spike · 75 viewers · sonion ×34** · dropbox · uploaded · 75 participants · 49 reactions · score 2.78
- 2026-11-16T00:47:52.793Z · **Chat spike · 92 viewers · LOL ×27** · dropbox · uploaded · 92 participants · 73 reactions · score 3.41
- 2026-11-16T00:30:12.541Z · **Chat spike · 59 viewers · RT ×23** · dropbox · uploaded · 59 participants · 53 reactions · score 3.37
- 2026-11-16T00:28:17.518Z · **Chat spike · 55 viewers · LOL ×21** · dropbox · uploaded · 55 participants · 32 reactions · score 3.44
- 2026-11-16T00:26:17.500Z · **Chat spike · 45 viewers · AURA ×12** · dropbox · uploaded · 45 participants · 40 reactions · score 3
- 2026-11-16T00:23:52.462Z · **Chat spike · 57 viewers · ALMOSTT ×31** · dropbox · uploaded · 57 participants · 40 reactions · score 3.8

## Bugs / risks

- **1 unusually small clip** (Chat spike · 66 viewers · aga ×33 — 6.1 MB). For 30-second 9:16 video, that can indicate a stalled frame, static scene, or encoder bitrate collapse.
- **10 auto-clip pair(s) fired within 5 minutes** — review whether they are distinct moments or duplicate/near-duplicate triggers: Chat spike · 126 viewers · mee ×60 → Chat spike · 184 viewers · LOL ×136 (3.0 min); Chat spike · 76 viewers · LOL ×9 → Chat spike · 77 viewers · gg ×15 (4.6 min); Chat spike · 77 viewers · gg ×15 → Chat spike · 381 viewers · LOL ×117 (1.8 min); Chat spike · 66 viewers · aga ×33 → Chat spike · 66 viewers · LOL ×35 (3.8 min); Chat spike · 66 viewers · LOL ×35 → Chat spike · 78 viewers · geeg ×25 (3.4 min).

## Key improvements

- **No usage log yet.** Launch the app once with this build, then run the audit again to capture page views, sessions, and chat samples.
- **No chat samples yet.** Chat thresholds/scores will appear here after a live capture with this build.
- **History and sidecars are separate stores.** A clip can be present in one but not the other; reconcile by remote path and clip ID.
- **No completed capture session in the usage log yet.** Start/stop once so the audit can measure session duration and clip yield.
- **Local cleanup is aggressive.** Most clips are remote-only; a failed cloud account logout can leave no playable local fallback. Consider keeping the newest 3–5 clips locally.
- **Dropbox is active; Google Drive is not configured.** The destination cards imply parity, but only Dropbox has credentials.
- **`keepLocalCopy` is off** while uploads are the only durable copy. This is efficient but risky on upload failure.

## Optimizations

- Use **chat message rate + unique participants** as two independent signals. The current trigger is driven by participants with a reaction-count floor; a raid can inflate participants without a genuine reaction spike.
- Add a **short-term vs long-term baseline** (30–60 s vs 15–30 min). The current `paceHistory` is a single recent window series, so a long slow build can look normal while a sudden burst is missed.
- Weight **emotes and repeated messages** differently from unique chatters, and require a minimum of *new* messages, not just unique reactors.
- Add **per-channel profiles** (small / medium / large chat). A global `minParticipants` and `minReactions` will over-trigger in small chats and under-trigger in large ones.
- Suppress **near-duplicate clips** for 3–5 minutes per channel, or merge them into one longer clip. The current 90-second cooldown is short for a sustained hype wave.
- Rank clips by a **quality score** (score, reactions/message, emote diversity, audio peak) and auto-discard low-quality exports before upload.
- Log **encoder output size and bitrate** per clip. The current size spread is large; a 6–7 MB clip may be a static or failed frame path.
- Persist **engine stderr/exit reason** in the usage log. The UI currently stores only the latest error string; a crash after a session leaves little evidence.
- Add **session-level counters** (messages, unique chatters, triggers, accepted clips). This makes tuning possible without storing every chat message.
- Review **upload retry backoff and queue visibility**. Queue is empty now, but the UI should show the next retry time and last error, not just a count.

## Potential features

- **Live chat activity panel** in Capture: messages/min, unique chatters, current score, threshold, and a sparkline of the last 15 minutes.
- **Sensitivity presets** (Conservative / Balanced / Aggressive) plus per-channel overrides, with a live preview of what would have triggered.
- **Clip review queue** with Good / Bad / Delete; feed ratings back into per-channel scoring and cooldown.
- **Raid / host / hype-train detection** as explicit trigger reasons, separate from organic chat spikes.
- **Auto-caption and brand templates** per channel: caption style, logo, safe-zone crop, intro/outro.
- **Multi-destination upload** with a primary + backup destination and local fallback.
- **Clip retention rules** (keep newest N, keep starred, delete after days) and a storage usage meter.
- **Discord/Slack webhook** or local notification when a clip is ready, with a link to review.
- **Per-channel analytics** (clips per hour, best-performing triggers, upload success rate) for done-for-you clipping.
- **Local-first privacy mode**: chat samples and diagnostics stay on-device with an explicit export button.

## Data quality notes

- The app stores **history** and **sidecars** separately. This audit merges them by remote/local path; if you see a clip only in one store, that is a reconciliation gap.
- No local 9:16 files are present in the clips folder; the current workflow uploads and deletes them. Raw/intermediate media: 4 file(s), 70.7 MB.
- Usage log: not created yet — this app build writes it on launch.
- Chat samples should be inspected after a live session; the current report's clip statistics come from sidecars.

## Chat-spike detection notes

The current detector evaluates **5-second windows** of unique participants and reactors. It uses a warmup of 12 windows, a 95th-percentile-capped median/MAD baseline, a threshold of `max(minParticipants, median × 1.5, adaptive)`, and a reaction floor of `max(minReactions, participants × minReactionShare)`. Auto-triggers have a 90-second cooldown.

This is a sensible baseline, but it measures **who showed up**, not **how much chat happened**. A raid can produce many unique participants with few messages; a dense, funny chat can produce many messages from a smaller group and still be missed. The best next step is to add `messagesPerWindow`, `messagesPerMinute`, and `newChatterRatio` to the score and show them live.

## Best next actions

1. **Add message-rate telemetry.** Before changing thresholds, log `messagesPerWindow`, `messagesPerMinute`, unique chatters, and emote counts for both triggered and non-triggered windows.
2. **Add per-channel profiles + longer dedupe.** One global threshold and a 90-second cooldown are too blunt for a mix of small and large chats.
3. **Keep the newest 3–5 local clips.** The current remote-only result is efficient, but a failed upload or expired Dropbox session leaves no editable copy.
4. **Review the 6.1 MB clip and the 10 close pairs.** They are the clearest current quality signals.

## How to keep this log current

```sh
# After a capture session:
npm run usage:audit
```

The app appends local events to `usage.jsonl` in the state directory. The audit rotates nothing itself; `usage.jsonl` rotates at 16 MB in the app. To include a snapshot in diagnostics, use the app's **Export Diagnostics** action.
