# Third-party notices

Chatclip bundles or links the following components. This file is a summary; the full license texts must ship with the release.

## FFmpeg

- **Version:** 7.1.1
- **License:** LGPL v2.1 or later (built with `--disable-gpl --disable-nonfree`)
- **Why:** capture/remux, MP4 export, 9:16 reframing, VideoToolbox H.264, AAC.
- **Source:** https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz
- **Build:** `tools/build-runtime.sh` records the exact configure flags. This build does not include libx264 or other GPL components. `boxblur` is GPL-dependent in FFmpeg 7.1 and is not used; the reframe filter uses `gblur`.
- **LGPL compliance:** provide the license text, this notice, and the corresponding source/build instructions (or a written offer) with the app.

### Written source offer (FFmpeg, LGPL)

The FFmpeg libraries and binary in this app are licensed under the GNU Lesser General Public License v2.1 or later. You may obtain the complete corresponding source from <https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz>. The build recipe, including every `./configure` flag used, is `tools/build-runtime.sh` in this project. For three years after you receive a copy of the app, you may also request the source and build scripts directly from the publisher at `<SUPPORT EMAIL — fill in before release>`. You may replace the bundled FFmpeg with your own build of the same libraries; the app looks for it in `Contents/Resources/runtime/bin`. The full LGPL text must ship in the app bundle alongside this notice.

## Windows runtime (FFmpeg and Streamlink)

The Windows app bundles builds that CI downloads and verifies against pinned SHA-256 values in `tools/runtime-win.json`.

- **FFmpeg:** BtbN `win64-lgpl` build `n7.1.5-12-g1fdbca85aa` (release `autobuild-2026-07-31-14-10`). `tools/verify-runtime.js` fails the build if the binary reports `--enable-gpl` or `--enable-nonfree`, or contains `libx264`/`libx265`/`libxvid`. The verified build contains the encoders `h264_nvenc`, `h264_qsv`, `h264_amf`, `h264_mf` (Windows Media Foundation) and `libopenh264`. The exact configure flags, the corresponding source and the LGPL source offer still have to be recorded from that release before shipping (the release notes link its build scripts). If `libopenh264` is used, review the OpenH264 licence and patent position, because a copy built into FFmpeg is not covered by Cisco's binary licence.
- **Streamlink:** 8.6.3 (`streamlink-8.6.3-1-py315-x86_64.zip`, portable build from `streamlink/windows-builds`). BSD 2-Clause, as for the macOS build; the portable folder also carries its own Python and Python packages, whose licences ship in that folder.

## Streamlink

- **Version:** 8.6.2
- **License:** BSD 2-Clause
- **Use:** resolves Twitch streams locally.

## Python

- **Version:** 3.12 (embedded by PyInstaller)
- **License:** PSF License
- **Use:** Streamlink runtime.

## PyInstaller

- **Version:** 6.14.2
- **License:** GPL v2 with a special exception that permits distribution of bundled applications.
- **Use:** builds the self-contained Streamlink executable.

## Node.js

- **Version:** bundled Node runtime (currently 24.x)
- **License:** MIT and third-party licenses included with Node.
- **Use:** recorder engine, OAuth/license helpers.

## Sparkle

- **Version:** 2.10.1
- **License:** MIT
- **Use:** auto-update and EdDSA update signature verification.

## Apple frameworks

Cocoa, Security, VideoToolbox, AudioToolbox, and other system frameworks are used under the macOS SDK terms.

## 7TV

Public emote metadata and images are fetched from `7tv.io`/`cdn.7tv.app`; no code is bundled.

## Trademarks

Twitch, TikTok, Dropbox, Google Drive, and Lemon Squeezy are trademarks of their respective owners. Chatclip is not affiliated with or endorsed by them.
