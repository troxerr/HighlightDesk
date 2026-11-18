"use strict";

const { spawnSync } = require("node:child_process");

const DEFAULT_BITRATE = "8M";
const HARDWARE = ["h264_nvenc", "h264_qsv", "h264_amf"];
// h264_mf is the Windows Media Foundation encoder; it works on any Windows PC.
const PROBE_ORDER = {
  win32: [...HARDWARE, "h264_mf"],
  darwin: ["h264_videotoolbox"],
  linux: []
};
const SUPPORTED = new Set(["auto", "h264_videotoolbox", "h264_nvenc", "h264_qsv", "h264_amf", "h264_mf", "libx264"]);

function bitrateFor(width = 1080, height = 1920) {
  const pixels = Math.max(1, Number(width) || 1080) * Math.max(1, Number(height) || 1920);
  const bits = Math.round(Math.min(16_000_000, Math.max(4_000_000, pixels * 30 * 0.12)));
  return `${Math.round(bits / 100000) / 10}M`;
}

function rateArgs(bitrate) {
  return ["-b:v", bitrate, "-maxrate", bitrate, "-bufsize", bitrate];
}

function videoEncoderArgs({ codec = process.env.HIGHLIGHT_DESK_ENCODER || "auto", bitrate = DEFAULT_BITRATE } = {}) {
  if (codec === "auto") codec = resolveEncoder();
  switch (codec) {
    case "libx264":
      return ["-c:v", "libx264", "-preset", "veryfast", "-crf", "20"];
    case "h264_videotoolbox":
      return ["-c:v", "h264_videotoolbox", ...rateArgs(bitrate), "-allow_sw", "1"];
    case "h264_nvenc":
      return ["-c:v", "h264_nvenc", "-preset", "p4", "-rc", "vbr", ...rateArgs(bitrate)];
    case "h264_qsv":
      return ["-c:v", "h264_qsv", ...rateArgs(bitrate)];
    case "h264_amf":
      return ["-c:v", "h264_amf", "-quality", "speed", "-rc", "vbr_peak", ...rateArgs(bitrate)];
    case "h264_mf":
      return ["-c:v", "h264_mf", "-b:v", bitrate];
    default:
      throw new Error(`Unsupported video encoder: ${codec}`);
  }
}

function normalizedEncoder(value, platform = process.platform) {
  if (SUPPORTED.has(value)) return value;
  return platform === "darwin" ? "h264_videotoolbox" : "auto";
}

// Try a one-second test encode. Hardware encoders are listed by ffmpeg even
// when the PC has no matching GPU, so only an actual encode proves one works.
function canEncode(ffmpegPath, codec, spawnImpl = spawnSync) {
  const args = [
    "-hide_banner", "-loglevel", "error",
    "-f", "lavfi", "-i", "color=c=black:s=256x256:r=30:d=1",
    "-frames:v", "10",
    ...videoEncoderArgs({ codec, bitrate: "1M" }),
    "-pix_fmt", "yuv420p", "-f", "null", "-"
  ];
  try {
    const result = spawnImpl(ffmpegPath, args, { encoding: "utf8", timeout: 15000, windowsHide: true });
    return result.status === 0;
  } catch {
    return false;
  }
}

const resolved = new Map();

// First working encoder for this machine; falls back to the last candidate
// (or videotoolbox/h264_mf by platform) so callers always get a name.
function resolveEncoder({ ffmpegPath = "ffmpeg", platform = process.platform, spawnImpl = spawnSync, order, refresh = false } = {}) {
  const list = order || PROBE_ORDER[platform] || [];
  const key = `${ffmpegPath}|${platform}|${list.join(",")}`;
  if (!refresh && resolved.has(key)) return resolved.get(key);
  let choice = null;
  for (const codec of list) {
    if (canEncode(ffmpegPath, codec, spawnImpl)) { choice = codec; break; }
  }
  if (!choice) choice = list[list.length - 1] || (platform === "darwin" ? "h264_videotoolbox" : "libx264");
  resolved.set(key, choice);
  return choice;
}

module.exports = {
  DEFAULT_BITRATE,
  SUPPORTED,
  PROBE_ORDER,
  bitrateFor,
  videoEncoderArgs,
  normalizedEncoder,
  canEncode,
  resolveEncoder
};
