# Legal review brief: Highlight Desk (Windows)

For a lawyer reviewing a small software product before it is sold. Prepared from the code and docs in this repository; it is not legal advice and nothing here has been reviewed by a lawyer. Items marked **[not verified]** are things the author could not check.

## What I am asking (in priority order)

1. **Open-source licensing.** Can I redistribute the bundled Windows FFmpeg (LGPL v3 or later, statically linked, many libraries) inside a paid, closed-source app? Is my written source offer and notice enough, and what else must ship with the installer? (Section 4)
2. **Recording and platform terms.** Is it acceptable to sell a tool that records a Twitch channel's public stream and chat, and what must the terms and the app say to put the responsibility for permission on the user? (Section 5)
3. **My documents.** Please mark up the EULA, Terms and Privacy Policy templates in `site/` (they were written for a Mac version and have placeholders), and tell me what is missing. (Section 6)
4. **Codec patents.** Do H.264/AAC (and the other codecs compiled into FFmpeg) create a licensing obligation for a product like this at my size? (Section 4.3)

A flat fee for written answers to these four questions is what I am after. Please tell me what you would need to see beyond this brief.

## 1. The product

Highlight Desk watches a streamer's Twitch chat, saves the 30 seconds of video around moments chat reacts to, reframes them to 9:16 (vertical), and stores them locally or in the user's own Dropbox or Google Drive. It also has a mode that scans a past broadcast's chat replay and cuts clips from it, with optional burned-in text and captions.

- It runs entirely on the user's PC. **There is no server operated by me.** I do not receive clips, chat, or credentials.
- A macOS version exists (not yet sold). The Windows version is being built; the app shell does not exist yet, but the engine, installer-independent pieces, and licensing helper do.
- Sold as a download with a 7-day trial, then a license key. Price not final (a one-time $39 is being tested; a subscription is under consideration). Payment, tax/VAT, refunds and key delivery by **Lemon Squeezy as merchant of record**. License limited to two PCs.
- Customers are streamers (some may be minors) who want TikTok/Reels/Shorts clips. **[age profile not verified]**
- Seller: **[no legal entity yet]**. Jurisdiction: **[to be filled in]**. Customers: worldwide, including the EU and UK.

## 2. What data goes where

| Data | Where it goes | Notes |
|---|---|---|
| Twitch video of the channel being watched | Pulled locally with Streamlink; kept as short rolling segments on the user's disk, then clips | Public stream; no Twitch login used |
| Twitch chat, live capture | Read anonymously from Twitch's chat service; counted per 5-second window | Usernames are used only to count unique chatters. The live recorder does not write chat messages to disk (it keeps counts and top emotes in the clip record) |
| Twitch chat, past-broadcast mode | Downloaded from Twitch's chat replay and **saved in full as a JSON file in the user's clip folder** (`chat-....json`), including each message's text, its offset and the **lowercased username** | Stays on the user's PC; nothing is uploaded unless the user copies it. It is not deleted automatically |
| Top chat message per clip | A local log (`feedback.jsonl`) records, for each past-broadcast clip, the most repeated message (first 60 characters) and how many chatters sent it | Local only. Used to help me tune clip selection from the user's own ratings |
| A chat message burned into a clip | Optional (`--hook`), past-broadcast mode: the most repeated message near the moment is drawn above the video | Message text only, no username shown. This puts a viewer's words into a video the user may post publicly |
| Captions | Optional: speech transcribed locally with whisper.cpp; the model file is downloaded once from Hugging Face | No audio leaves the PC |
| Finished clips and a JSON record | User's disk; optionally uploaded to the user's own Dropbox or Google Drive account | Uses the user's OAuth consent. Tokens are encrypted per user on Windows (DPAPI) |
| License key | Sent to Lemon Squeezy to activate/validate | Stored locally |
| Emote metadata | Fetched from 7TV (`7tv.io`, `cdn.7tv.app`) | Public data |
| Local diagnostics and "monitor" logs | User's disk only | Aggregate counts and ratings the user gives clips; retained 30 days, per `docs/MONITORING.md` |
| Updates | The Mac build uses Sparkle; a Windows update feed is planned | Feed not hosted yet |
| Crash reports | The privacy template says "if you opt in". **Not built.** | Decide before launch whether to collect any |

Other hosts the code contacts: Twitch (chat, player, and `gql.twitch.tv` for VOD/chat replay), Dropbox and Google APIs, Lemon Squeezy, Hugging Face. Kick support exists in the engine but is **not** part of the Windows launch.

## 3. What is not built yet

So you do not review something that does not exist: the Windows app (Electron) shell and installer, an OBS-based capture source, the update feed, crash reporting, and code signing. The site and legal pages are templates.

## 4. Open-source and third-party licensing

### 4.1 FFmpeg (the main question)

- The Windows build bundles a prebuilt third-party FFmpeg: `ffmpeg version n7.1.5-12-g1fdbca85aa-20260731`, a BtbN "win64-lgpl" build, pinned by SHA-256 in `tools/runtime-win.json`.
- Its configure line has `--enable-version3` and has **neither `--enable-gpl` nor `--enable-nonfree`**. So I treat it as **LGPL v3 or later**. `libx264`, `libx265`, `libxvid` and `libfdk-aac` are disabled. CI fails the build if it ever reports GPL or non-free, and checks that the configure line in the notice matches the binary.
- It is **one statically linked `ffmpeg.exe`** with many libraries compiled in (for example libvpx, libaom, libsvtav1, libopus, libass, libopenjpeg, libvmaf, libsrt, libssh, libplacebo, libopencore-amr, libzvbi, libmp3lame, libtwolame, libopenh264). The app starts it as a separate process and never links to it. It is shipped unmodified.
- The full configure line, version, source locations and a draft written offer are in **`docs/THIRD_PARTY_NOTICES.md`** (section "Windows runtime"). Source links there are marked unchecked, and the support contact is a placeholder.
- BtbN deletes old builds. I intend to keep a copy of the exact archive and source myself so the offer can be honored for three years or more.

Questions: Is a separate-process, unmodified, statically linked LGPL v3 binary acceptable? What exactly must I ship (licence texts, notices, source or an offer, installation information)? Are the other bundled libraries' licences a problem in a closed-source product, given FFmpeg's own configure rules (it did not need `--enable-gpl`)?

### 4.2 Other components

Streamlink (BSD 2-Clause; portable build with its own Python and packages), Node.js or Electron (MIT plus bundled licences), whisper.cpp and a model file downloaded from Hugging Face **[model licence not verified]**, 7TV data. Licence texts will ship in the installer.

### 4.3 Codec patents

The product encodes H.264 video and AAC audio, using the PC's hardware/Windows encoders or the software `libopenh264`. FFmpeg also contains encoders and decoders for other patent-encumbered formats (HEVC, VVC, AV1 and others) that the app does not use. A copy of OpenH264 built into FFmpeg is not covered by Cisco's patent licence for its own prebuilt binaries.

Question: At my scale, is there a patent-licence obligation I should handle, and should I remove the unused codecs by building a minimal FFmpeg?

## 5. Recording, platform terms and permission

- **Modes:** (a) watch any public Twitch channel by URL with Streamlink; (b) clip the user's own stream through OBS (planned, and what I would like to lead with); (c) scan a past broadcast's chat replay and download the VOD, via Twitch's unofficial `gql.twitch.tv` interface with Twitch's public web client ID, which is not a sanctioned API **[Twitch terms not reviewed]**.
- The terms template already requires the user to have permission to record the channels they monitor, and to follow Twitch's terms, copyright and privacy law. The onboarding shows a permission checkbox.
- Clips are made for the user to post elsewhere, and may contain a streamer's voice and face, game footage, music, and viewers' chat text.
- The app does not post anywhere itself.

Past-broadcast mode (c) also keeps a full chat transcript with usernames on the user's disk, and can show a viewer's message in a clip the user posts publicly. Please say whether that needs a notice to users, a retention limit, or an opt-out.

Questions: Does selling mode (a) or (c) expose me to Twitch's terms or to claims of contributory infringement or circumvention, and should I drop or restrict either? Does making the permission statement a condition of use, plus a checkbox, adequately move responsibility to the user? Anything about recording other people (voices, chat messages) under US/EU/UK law I should handle in the app?

## 6. My documents

`site/privacy.html`, `site/terms.html` and `site/eula.html` are templates, and say so. They need work I cannot judge:

- They say "macOS application", "Keychain", "two Macs" and "macOS version"; the Windows product needs Windows wording (DPAPI-encrypted credentials, two PCs, Windows updates).
- Placeholders for entity, address, date and contact.
- The EULA says FFmpeg is "LGPL"; the Windows build is LGPL v3 or later.
- The privacy text mentions opt-in crash reports (not built), and I need correct GDPR/UK GDPR and CCPA wording given there is no server and I act mostly as a software vendor. Is a data-processing or cookie notice needed for a download site?
- Refunds are handled through Lemon Squeezy's checkout policy; I need terms that match it, and EU/UK consumer-right wording for digital downloads and the trial.
- Do I need an age restriction (Twitch requires 13+), a limitation of liability, and a disclaimer that clips may infringe third-party rights?
- Trademark: the name "ChatClip" (formerly Highlight Desk) has not been searched for trademark conflicts. **[not verified]**

## 7. Attach

`docs/THIRD_PARTY_NOTICES.md`, `site/privacy.html`, `site/terms.html`, `site/eula.html`, `tools/runtime-win.json`, `docs/MONITORING.md`, `docs/WINDOWS_PLAN.md` (business context; includes pricing ideas), and `docs/COMMERCIAL_CHECKLIST.md`.

## 8. How this brief was made

An AI assistant wrote it from the repository. It has not been checked against the live GitHub, FFmpeg, Twitch or Hugging Face pages; verify anything you rely on. The author is not a lawyer.
