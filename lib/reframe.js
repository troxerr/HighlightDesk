"use strict";

const { spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { videoEncoderArgs, bitrateFor } = require("./encoder.js");
const { applyPriority } = require("./priority.js");

const activeChildren = new Set();

// extraFilters: optional filter steps (drawtext, subtitles, ...) run on the
// finished 9:16 frame inside the same encode. Existing callers pass nothing.
function buildReframeFilter({ width, height, blur, extraFilters = [] }) {
  const halfWidth = Math.max(2, Math.floor(width / 4) * 2);
  const halfHeight = Math.max(2, Math.floor(height / 4) * 2);
  return [
    "[0:v]split=2[bg][fg]",
    `[bg]scale=${halfWidth}:${halfHeight}:force_original_aspect_ratio=increase,crop=${halfWidth}:${halfHeight},gblur=sigma=${blur}:steps=5,scale=${width}:${height},setsar=1[bgout]`,
    `[fg]scale=${width}:${height}:force_original_aspect_ratio=decrease,setsar=1[fgout]`,
    ["[bgout][fgout]overlay=(W-w)/2:(H-h)/2:format=auto", ...(extraFilters || []).filter(Boolean), "format=yuv420p[v]"].join(",")
  ].join(";");
}

function buildArgs({ input, output, width, height, blur, bitrate = "8M", encoder, extraFilters }) {
  return [
    "-hide_banner",
    "-loglevel", "error",
    "-nostdin",
    "-y",
    "-i", input,
    "-filter_complex", buildReframeFilter({ width, height, blur, extraFilters }),
    "-map", "[v]",
    "-map", "0:a?",
    ...videoEncoderArgs({ codec: encoder, bitrate }),
    "-pix_fmt", "yuv420p",
    "-c:a", "aac",
    "-b:a", "160k",
    "-movflags", "+faststart",
    "-f", "mp4",
    output
  ];
}

function reframeClip({
  input,
  output,
  width = 1080,
  height = 1920,
  crf = 20,
  preset = "veryfast",
  blur = 20,
  bitrate,
  encoder,
  priority,
  ffmpegPath = "ffmpeg",
  timeoutMs = 180000,
  extraFilters = []
}) {
  if (!input || !fs.existsSync(input)) {
    return Promise.resolve({ ok: false, error: `Input not found: ${input}` });
  }
  if (!output) return Promise.resolve({ ok: false, error: "No output target." });

  const draft = output + ".partial";
  try {
    fs.mkdirSync(path.dirname(output), { recursive: true });
    fs.rmSync(draft, { force: true });
  } catch (error) {
    return Promise.resolve({ ok: false, error: error.message });
  }

  return new Promise((resolve) => {
    let settled = false;
    let stderr = "";
    let timer = null;

    const finish = (result) => {
      if (settled) return;
      settled = true;
      if (timer) clearTimeout(timer);
      if (!result.ok) {
        try { fs.rmSync(draft, { force: true }); } catch {}
      }
      resolve(result);
    };

    let child;
    try {
      child = spawn(ffmpegPath, buildArgs({ input, output: draft, width, height, blur, bitrate: bitrate || bitrateFor(width, height), encoder, extraFilters }), {
        stdio: ["ignore", "ignore", "pipe"]
      });
    } catch (error) {
      finish({ ok: false, error: error.message });
      return;
    }

    applyPriority(child, priority);
    activeChildren.add(child);
    timer = setTimeout(() => {
      try { child.kill("SIGKILL"); } catch {}
      finish({ ok: false, error: `Reframe timed out after ${Math.round(timeoutMs / 1000)}s.` });
    }, timeoutMs);

    child.stderr.on("data", (chunk) => {
      stderr += chunk;
      if (stderr.length > 8000) stderr = stderr.slice(-8000);
    });

    child.on("error", (error) => {
      activeChildren.delete(child);
      finish({ ok: false, error: error.message });
    });

    child.on("close", (code) => {
      activeChildren.delete(child);
      if (settled) return;
      let size = 0;
      try { size = fs.statSync(draft).size; } catch {}
      if (code !== 0 || size <= 0) {
        finish({ ok: false, error: stderr.trim() || `FFmpeg reframe exited with code ${code}.` });
        return;
      }
      try {
        fs.renameSync(draft, output);
      } catch (error) {
        finish({ ok: false, error: error.message });
        return;
      }
      finish({ ok: true, path: output, bytes: size, width, height });
    });
  });
}

function killAll() {
  for (const child of activeChildren) {
    try { child.kill("SIGKILL"); } catch {}
  }
  activeChildren.clear();
}

module.exports = {
  buildReframeFilter,
  buildArgs,
  reframeClip,
  killAll
};
