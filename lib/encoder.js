"use strict";

const DEFAULT_BITRATE = "8M";
const SUPPORTED = new Set(["h264_videotoolbox", "libx264"]);

function bitrateFor(width = 1080, height = 1920) {
  const pixels = Math.max(1, Number(width) || 1080) * Math.max(1, Number(height) || 1920);
  const bits = Math.round(Math.min(16_000_000, Math.max(4_000_000, pixels * 30 * 0.12)));
  return `${Math.round(bits / 100000) / 10}M`;
}

function videoEncoderArgs({ codec = process.env.HIGHLIGHT_DESK_ENCODER || "h264_videotoolbox", bitrate = DEFAULT_BITRATE } = {}) {
  if (codec === "libx264") {
    return ["-c:v", "libx264", "-preset", "veryfast", "-crf", "20"];
  }
  if (codec === "h264_videotoolbox") {
    return [
      "-c:v", "h264_videotoolbox",
      "-b:v", bitrate,
      "-maxrate", bitrate,
      "-bufsize", bitrate,
      "-allow_sw", "1"
    ];
  }
  throw new Error(`Unsupported video encoder: ${codec}`);
}

function normalizedEncoder(value) {
  return SUPPORTED.has(value) ? value : "h264_videotoolbox";
}

module.exports = {
  DEFAULT_BITRATE,
  SUPPORTED,
  bitrateFor,
  videoEncoderArgs,
  normalizedEncoder
};
